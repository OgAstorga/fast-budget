require 'sinatra/base'
require 'mongoid'

class AppController < Sinatra::Base
  configure :production, :development do
    enable :logging

    Mongoid.logger.level = Logger::WARN
    Mongo::Logger.logger.level = Logger::WARN

    Mongoid.configure do |config|
      config.clients.default = {
        hosts: [ENV['MONGODB_HOST']],
        database: ENV['MONGODB_DB'],
      }
    end
  end

  configure :test do
    set :raise_errors, true
    set :show_exceptions, false

    Mongoid.logger.level = Logger::WARN
    Mongo::Logger.logger.level = Logger::WARN

    Mongoid.configure do |config|
      config.clients.default = {
        hosts: [ENV['MONGODB_HOST']],
        database: ENV['MONGODB_TESTDB'],
      }
    end
  end
end
