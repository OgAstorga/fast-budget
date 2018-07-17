require_relative './app'

class TelegramController < AppController
  post '/webhook/:secret' do
    if params[:secret] != ENV['TELEGRAM_SECRET']
      halt 401
    end

    [200, 'grant']
  end
end

