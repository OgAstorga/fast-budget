require 'minitest/autorun'
require 'rack/test'

require_relative './telegram.rb'
require_relative '../models/main.rb'
require_relative '../helpers/mock-client'

def update_generator(user, message, action = 'message')
  update = {
    'update_id' => 1,
    action => {
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
        'id' => message['chat_id'],
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

def simple_update_generator(message, message_id = 1, chat_id = 1, user_id = 1)
  update_generator({
    'id' => user_id,
    'username' => 'mkundera',
    'first_name' => 'Milan',
    'last_name' => 'Kundera',
  }, {
    'id' => message_id,
    'chat_id' => chat_id,
    'text' => message,
  })
end

class TelegramControllerSpec < MiniTest::Test
  include Rack::Test::Methods

  def app
    TelegramController
  end

  def setup
    MockClient.requests = []
    User.where(:_id.exists => 1).delete
    Category.where(:_id.exists => 1).delete
    Transaction.where(:_id.exists => 1).delete
  end

  def test_webhook_auth
    post "/webhook/r8O3JnU3O91uegYj", '{"update_id": 1}'
    assert_equal 401, last_response.status

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", '{"update_id": 1}'
    assert_equal 200, last_response.status
  end

  def test_chat_malformed
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", '{"updated_id": 1'

    assert_equal 400, last_response.status
  end

  def test_chat_init
    uid = rand(1000)
    mid = rand(1000)
    cid = rand(1000000000000000).to_s

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => uid,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => mid,
      'chat_id' => cid,
      'text' => '/start',
    })

    assert User.where(_id: uid).exists?
    assert_equal 200, last_response.status
    assert_equal 1, MockClient.requests.length
    assert_equal ({
      chat_id: cid,
      text: 'welcome'
    }).to_json, MockClient.requests[0][:payload]
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
      'chat_id' => '1',
      'text' => '/start',
    })

    assert User.where(_id: uid).exists?
  end

  def test_log_spending
    mid = rand(1000)
    cid = rand(1000000000000000)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => 1,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => mid,
      'chat_id' => cid.to_s,
      'text' => '147 machine learning',
    })

    transaction = Transaction.find_by(chat_id: cid, message_id: mid)

    assert transaction != nil
    assert_equal 1, transaction[:user_id]
    assert_equal mid, transaction[:message_id]
    assert_equal cid.to_s, transaction[:chat_id]
    assert_equal 147.0, transaction[:amount]
    assert_equal 'machine learning', transaction[:description]
  end

  def test_edit_transaction
    mid = rand(1000)
    cid = rand(1000)

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => 1,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => mid,
      'chat_id' => cid,
      'text' => '147 machine learning',
    })

    transaction = Transaction.find_by(chat_id: cid, message_id: mid)

    assert_equal 147.0, transaction[:amount]
    assert_equal 'machine learning', transaction[:description]


    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => 1,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => mid,
      'chat_id' => cid,
      'text' => '13.5 cookies',
    }, 'edited_message')

    transaction = Transaction.find_by(chat_id: cid, message_id: mid)

    assert_equal 13.5, transaction[:amount]
    assert_equal 'cookies', transaction[:description]


    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => 1,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => mid,
      'chat_id' => cid,
      'text' => 'no transaction',
    }, 'edited_message')

    assert Transaction.where(chat_id: cid, message_id: mid).exists? == false
  end

  def test_transaction_category
    mid = rand(1000)
    cid = rand(1000)

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => 1,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => mid,
      'chat_id' => cid,
      'text' => '147 machine learning #education',
    })

    category = Category.find_by(slug: 'education')
    transactions = category.transactions

    assert_equal 1, transactions.length
    assert_equal mid, transactions[0].message_id
    assert_equal cid.to_s, transactions[0].chat_id
  end

  def test_set_budget
    mid = rand(1000)
    cid = rand(1000)

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator({
      'id' => 1,
      'username' => 'mkundera',
      'first_name' => 'Milan',
      'last_name' => 'Kundera',
    }, {
      'id' => mid,
      'chat_id' => cid,
      'text' => '/budget 80000',
    })

    user = User.find(1)
    assert_equal 80000, user.budget
  end

  def test_stats
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", simple_update_generator('10 #a', 1, 1)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", simple_update_generator('20 #b', 2, 2)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", simple_update_generator('40 #a', 3, 3)

    MockClient.requests = []
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", simple_update_generator('/stats', 4, 4)
    assert_equal 1, MockClient::requests.length

    payload = JSON.parse MockClient::requests[0][:payload]
    assert_equal "#a 50.00\n#b 20.00", payload['text']
  end
end
