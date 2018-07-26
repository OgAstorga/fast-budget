require 'minitest/autorun'
require 'rack/test'

require_relative './mock-client'

class MockClientSpec < MiniTest::Test
  include Rack::Test::Methods

  def setup
    MockClient.requests = []
  end

  def test_post
    assert_equal 0, MockClient.requests.length

    MockClient.post(
      'https://google.com',
      'body_raw',
      { content_type: :json, accept: :json }
    )

    assert_equal 1, MockClient.requests.length
    assert_equal 'https://google.com', MockClient.requests[0][:url]
    assert_equal 'body_raw', MockClient.requests[0][:payload]
  end
end
