require_relative './app'
require_relative '../models/main.rb'

class TelegramController < AppController
  before do
    request.body.rewind
    body = request.body.read

    @body_hash = Hash.new
    if body.size > 0
      begin
        hash = JSON.parse body
        @body_hash = hash
      rescue
        # @TODO log to stderr
      end
    end
  end

  def self.handle_message(message, edit=false)
    from = message['from']

    if not User.where(_id: from['id']).exists?
      User.create(
        _id: from['id'],
        username: from['username'],
        first_name: from['first_name'],
        last_name: from['last_name'],
      )
    end

    user = User.find(from['id'])

    tokens = message['text'].split

    categories = []
    description = []
    amount = nil

    tokens.each do |token|
      if amount == nil and /^((\d+(\.\d+)?)|((\d+)?\.\d+))$/.match(token)
        amount = token.to_f
      elsif /^#[a-zA-Z0-9_]+$/.match(token)
        categories << token
      else
        description << token
      end
    end

    # Create categories
    categories = categories.map do |category|
      slug = category[1, category.length-1].downcase
      Category.find_or_create_by(slug: slug)
    end

    if edit
      transaction = Transaction.find_by(
        chat_id: message['chat']['id'],
        message_id: message['message_id']
      )

      if amount == nil
        transaction.delete
      else
        transaction.update_attributes(
          message: message['text'],
          timestamp: Time.at(message['date']),
          amount: amount,
          description: description.join(' '),
          categories: categories,
        )
      end
    elsif amount != nil
      Transaction.create(
        chat_id: message['chat']['id'],
        message_id: message['message_id'],
        message: message['text'],
        timestamp: Time.at(message['date']),
        amount: amount,
        description: description.join(' '),
        user: user,
        categories: categories,
      )
    end
  end

  post '/webhook/:secret' do
    if params[:secret] != ENV['TELEGRAM_SECRET']
      halt 401
    end

    if not @body_hash.has_key?('update_id')
      halt 400
    end

    if @body_hash.has_key?('message')
      self.class.handle_message @body_hash['message']
    elsif @body_hash.has_key?('edited_message')
      self.class.handle_message @body_hash['edited_message'], true
    end

    [200, 'grant']
  end
end
