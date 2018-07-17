require 'dotenv'

# load ENV vars
Dotenv.load('.env', '.env.base')

require 'app/controllers/telegram'
map('/telegram') { run TelegramController }
