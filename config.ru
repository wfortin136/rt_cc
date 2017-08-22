require './rtchallenge'
require 'logger'

configure do
  file = File.new("/var/log/piv_app/access.log","a+")
  file.sync = true
	use Rack::CommonLogger, file
end

run Sinatra::Application
