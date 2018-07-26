require 'minitest/autorun'
require 'rack/test'

require_relative './mock-client'
require_relative './bot-api'

class BotApiSpec < MiniTest::Test
  include Rack::Test::Methods

  def setup
    MockClient.requests = []
  end

  def test_send_message
    BotApi.send_message chat_id: 1, text: 'chat'

    url = String.new ENV['TELEGRAM_URI']
    url = url.sub! '<TELEGRAM_TOKEN>', ENV['TELEGRAM_TOKEN']
    url = url.sub! '<METHOD_NAME>', 'sendMessage'

    assert_equal 1, MockClient::requests.length
    assert_equal url, MockClient::requests[0][:url]
    assert_equal '{"chat_id":1,"text":"chat"}', MockClient::requests[0][:payload]
  end
end
