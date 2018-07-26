require_relative './app'
require_relative '../models/main.rb'
require_relative '../helpers/bot-api'

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

  def get_user(from)
    if not User.where(_id: from['id']).exists?
      User.create(
        _id: from['id'],
        username: from['username'],
        first_name: from['first_name'],
        last_name: from['last_name'],
        budget: 0,
      )
    end

    user = User.find(from['id'])
  end

  def command_start(message)
    get_user message['from']

    BotApi.send_message chat_id: message['chat']['id'], text: 'welcome'
  end

  def command_budget(message)
    user = get_user message['from']

    tokens = message['text'].split

    budget = nil

    tokens.each do |token|
      if budget == nil and /^((\d+(\.\d+)?)|((\d+)?\.\d+))$/.match(token)
        budget = token.to_f
      end
    end

    if budget == nil
      BotApi.send_message chat_id: message['chat']['id'], text: 'I don\'t get it'
    else
      user.update_attributes(
        budget: budget,
      )

      BotApi.send_message chat_id: message['chat']['id'], text: 'budget set!'
    end
  end

  def command_transaction(message)
    user = get_user message['from']

    tokens = message['text'].split

    categories = []
    description = []
    amount = nil

    tokens.each do |token|
      if amount == nil and /^((\d+(\.\d+)?)|((\d+)?\.\d+))$/.match(token)
        amount = token.to_f
      elsif /^#[a-zA-Z0-9_]+$/.match(token)
        categories << token
      elsif /^\/transaction$/.match(token)
        # ignore command
      else
        description << token
      end
    end

    # Create categories
    categories = categories.map do |category|
      slug = category[1, category.length-1].downcase
      Category.find_or_create_by(slug: slug)
    end

    is_edit = Transaction.where(
      chat_id: message['chat']['id'],
      message_id: message['message_id'],
    ).exists?

    if is_edit
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
      message =  @body_hash['message']
    elsif @body_hash.has_key?('edited_message')
      message = @body_hash['edited_message']
    else
      # I don't understand the update
      halt 200
    end


    tokens = message['text'].split
    fword = tokens[0]
    case fword
    when '/start'
      # Create user & explain how to use this bot
      command_start(message)
    when '/budget'
      # Set user budget
      command_budget(message)
    when '/transaction'
      # Create a new transaction
      command_transaction(message)
    else
      # Create a new transaction
      command_transaction(message)
    end

    [200, 'grant']
  end
end
