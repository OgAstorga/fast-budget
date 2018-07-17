require 'sinatra/base'

class AppController < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  configure :test do
    set :raise_errors, true
    set :show_exceptions, false
  end
end
