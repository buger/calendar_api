$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "mongo_mapper"
require "grape"

Dir.glob('lib/models/**/*.rb') { |f| require File.expand_path(f) }
require File.expand_path("lib/api/validators.rb")
Dir.glob('lib/api/**/*.rb') { |f| require File.expand_path(f) }

desc "Displays routes"
task 'routes' do
  CalendarAPI::routes.each do |route|
    options = route.instance_variable_get(:@options)

    meth   = options[:method]
    path   = options[:path]

    puts "#{meth} \t #{path}"
  end
end

