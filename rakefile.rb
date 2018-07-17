require 'rake/testtask'
require 'dotenv'

# load ENV vars
Dotenv.load('.env', '.env.base')

ENV['RACK_ENV'] = 'test'

Rake::TestTask.new do |t|
  t.pattern = 'app/controllers/*_spec.rb'
end
