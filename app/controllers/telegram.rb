require_relative './app'
require_relative '../models/user.rb'

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

  def self.handle_message(message)
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
  end

  post '/webhook/:secret' do
    if params[:secret] != ENV['TELEGRAM_SECRET']
      halt 401
    end

    if @body_hash.has_key?('update_id') == false
      halt 400
    end

    if @body_hash.has_key?('message')
      self.class.handle_message @body_hash['message']
    end

    [200, 'grant']
  end
end
