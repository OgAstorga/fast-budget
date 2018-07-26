require 'rest-client'

require_relative './mock-client'

class BotApi
  class << self
    def build_uri(method_name)
      uri = String.new ENV['TELEGRAM_URI']
      uri = uri.sub! '<TELEGRAM_TOKEN>', ENV['TELEGRAM_TOKEN']
      uri = uri.sub! '<METHOD_NAME>', method_name
    end

    def send_message(params)
      # build telegram uri
      uri = build_uri 'sendMessage'

      required = [
        :chat_id,
        :text
      ]
      optional = [
        :parse_mode,
        :disable_web_page_preview,
        :disable_notification,
        :reply_to_message_id,
        :reply_markup
      ]

      # build request payload
      data = Hash.new
      required.each do |attr|
        data[attr] = params[attr]
      end
      optional.each do |attr|
        data[attr] = params[attr] if !params[attr].nil?
      end
      payload = data.to_json

      # build headers
      headers = { content_type: :json, accept: :json }

      if ENV['RACK_ENV'] == 'test'
        MockClient.post uri, payload, headers
      else
        puts ""
        puts uri
        puts payload
        begin
          RestClient.post uri, payload, headers
        rescue RestClient::ExceptionWithResponse => err
          # @TODO Log failed request
          puts "failed"
          puts err
        end
      end
    end
  end
end
