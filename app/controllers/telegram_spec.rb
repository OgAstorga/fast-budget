require 'minitest/autorun'
require 'rack/test'

require_relative './telegram.rb'

class TelegramControllerSpec < MiniTest::Test
  include Rack::Test::Methods

  def app
    TelegramController
  end

  def test_webhook_auth
    post '/webhook/r8O3JnU3O91uegYj', '{"update_id": 1}'
    assert_equal last_response.status, 401

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", '{"update_id": 1}'
    assert_equal last_response.status, 200
  end

  def test_chat_malformed
    body = '{"updated_id": 1'
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", body

    assert_equal last_response.status, 400
  end

  def test_chat_init
    body = '{"update_id":1,
    "message":{"message_id":1,"from":{"id":1,"is_bot":false,"first_name":"Milan","last_name":"Kundera","username":"mkundera","language_code":"en-us"},"chat":{"id":1,"first_name":"Milan","last_name":"Kundera","username":"mkundera","type":"private"},"date":1531867796,"text":"/start","entities":[{"offset":0,"length":6,"type":"bot_command"}]}}'
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", body

    assert_equal last_response.status, 200
  end
end
