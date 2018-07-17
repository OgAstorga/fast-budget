require 'minitest/autorun'
require 'rack/test'

require_relative './telegram.rb'

class TelegramControllerSpec < MiniTest::Test
  include Rack::Test::Methods

  def app
    TelegramController
  end

  def test_webhook_auth
    post '/webhook/r8O3JnU3O91uegYj'
    assert_equal last_response.status, 401

    post "/webhook/#{ENV['TELEGRAM_SECRET']}"
    assert_equal last_response.status, 200
  end
end
