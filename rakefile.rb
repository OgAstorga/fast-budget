require 'rake/testtask'
require 'dotenv'

# load ENV vars
Dotenv.load('.env', '.env.base')

ENV['RACK_ENV'] = 'test'

# import spec files
Rake::TestTask.new do |t|
  t.pattern = 'app/*/*_spec.rb'
end
