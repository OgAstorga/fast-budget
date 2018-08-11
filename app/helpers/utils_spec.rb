require_relative './utils'

class BotApiSpec < MiniTest::Test
  include Rack::Test::Methods

  def test_format_number
    assert_equal '1.00', format_number(1)
    assert_equal '1,000,000.00', format_number(1000000)
    assert_equal '1,234.13', format_number(1234.1276)
  end
end

