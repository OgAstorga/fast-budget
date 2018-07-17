require_relative './app'

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

  post '/webhook/:secret' do
    if params[:secret] != ENV['TELEGRAM_SECRET']
      halt 401
    end

    if @body_hash.has_key?('update_id') == false
      halt 400
    end

    puts JSON.pretty_generate(@body_hash)

    [200, 'grant']
  end
end

