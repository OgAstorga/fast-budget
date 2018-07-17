require 'dotenv'

# load ENV vars
Dotenv.load('.env', '.env.base')

# define micro app
app = proc do |env|
  [
    200,
    {
      'Content-Type' => 'text/html',
      'Content-Length' => '12',
    },
    'Hello world!'
  ]
end

run app
