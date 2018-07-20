require 'minitest/autorun'
require 'rack/test'

require_relative './telegram.rb'
require_relative '../models/main.rb'

def update_generator(user, message)
  update = {
    'update_id' => 1,
    'message' => {
      'message_id' => message['id'],
      'from' => {
        'id' => user['id'],
        'is_bot' => false,
        'first_name' => user['first_name'],
        'last_name' => user['last_name'],
        'username' => user['username'],
        'language_code' => 'en-us',
      },
      'chat' => {
        'id' => user['id'],
        'first_name' => user['first_name'],
        'last_name' => user['last_name'],
        'username' => user['username'],
        'type' => 'private',
      },
      'date' => Time.now.to_i,
      'text' => message['text'],
      'entities' => [{
        'offset' => 0,
        'length' => message['text'].length,
        'type' => 'bot_command',
      }],
    },
  }

  update.to_json
end

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
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", '{"updated_id": 1'

    assert_equal last_response.status, 400
  end

  def test_chat_init
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => 1,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => 1,
      'text' => '/start',
    })

    assert_equal last_response.status, 200
  end

  def test_create_user
    uid = rand(1000)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => uid,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => 1,
      'text' => '/start',
    })

    assert User.where(_id: uid).exists?
  end
end
