require 'minitest/autorun'
require 'rack/test'

require_relative './telegram.rb'
require_relative '../models/main.rb'
require_relative '../helpers/mock-client'

def update_generator(text, message_id = 1, chat_id = 1, user_id = 1, action = 'message', date = Time.now.to_i, update_id = 1)
  update = {
    'update_id' => update_id,
    action => {
      'message_id' => message_id,
      'from' => {
        'id' => user_id,
        'is_bot' => false,
        'first_name' => 'mkundera',
        'last_name' => 'Milan',
        'username' => 'Kundera',
        'language_code' => 'en-us',
      },
      'chat' => {
        'id' => chat_id,
        'first_name' => 'Milan',
        'last_name' => 'Kundera',
        'username' => 'mkundera',
        'type' => 'private',
      },
      'date' => date,
      'text' => text,
      'entities' => [{
        'offset' => 0,
        'length' => text.length,
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
    mid = rand(1000)
    cid = rand(1000000000000000).to_s
    uid = rand(1000)

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('/start', mid, cid, uid)

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
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('/start', 1, 1, uid)

    assert User.where(_id: uid).exists?
  end

  def test_log_spending
    mid = rand(1000)
    cid = rand(1000000000000000)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('147 machine learning', mid, cid.to_s)

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

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('147 machine learning', mid, cid)

    transaction = Transaction.find_by(chat_id: cid, message_id: mid)

    assert_equal 147.0, transaction[:amount]
    assert_equal 'machine learning', transaction[:description]


    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('13.5 cookies', mid, cid, 1, 'edited_message')

    transaction = Transaction.find_by(chat_id: cid, message_id: mid)

    assert_equal 13.5, transaction[:amount]
    assert_equal 'cookies', transaction[:description]


    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('no transaction', mid, cid, 1, 'edited_message')

    assert Transaction.where(chat_id: cid, message_id: mid).exists? == false
  end

  def test_transaction_category
    mid = rand(1000)
    cid = rand(1000)

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('147 machine learning #education', mid, cid)

    category = Category.find_by(slug: 'education')
    transactions = category.transactions

    assert_equal 1, transactions.length
    assert_equal mid, transactions[0].message_id
    assert_equal cid.to_s, transactions[0].chat_id
  end

  def test_transaction_date
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('147 #education ~2018-01-01')
    transaction = Transaction.find_by(chat_id: 1, message_id: 1)
    assert_equal DateTime.new(2018, 1, 1), transaction.timestamp

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('147 #education ~2018-05-01', 1, 1, 1, 'edited_message')
    transaction = Transaction.find_by(chat_id: 1, message_id: 1)
    assert_equal DateTime.new(2018, 5, 1), transaction.timestamp
  end

  def test_set_budget
    mid = rand(1000)
    cid = rand(1000)

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('/budget 80000', mid, cid)

    user = User.find(1)
    assert_equal 80000, user.budget
  end

  def test_stats
    now = Time.now
    year = now.year
    month = now.strftime("%m").to_i
    last_month = Time.new(year, month - 1)

    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('10 #a', 1, 1, 1, 'message', last_month.to_i)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('10 #a', 2)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('20 #b', 3)
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('40 #a', 4)

    MockClient.requests = []
    post "/webhook/#{ENV['TELEGRAM_SECRET']}", update_generator('/stats', 5)
    assert_equal 1, MockClient::requests.length

    payload = JSON.parse MockClient::requests[0][:payload]

    title = now.strftime("%B %Y")
    assert_equal "%s\n\n#a 50.00\n#b 20.00" % [title], payload['text']
  end
end
