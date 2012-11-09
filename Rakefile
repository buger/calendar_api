$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "mongo_mapper"
require "grape"
require "pry"

require File.expand_path("lib/api/application_api.rb")
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

desc "seeds data"
task "ical" do
  require "ffaker"
  MongoMapper.database = "calendar_api"
  Dir.glob('lib/lib/**/*.rb') { |f| require File.expand_path(f) }
  Dir.glob('lib/models/**/*.rb') { |f| require File.expand_path(f) }

  sen = proc { Faker::Lorem.sentence[0..39] }

  customer = Customer.create
  cal = customer.calendars.create(title: sen[])
  cal.events.create(title: sen[], start: 5.days.ago, :end => 1.day.ago)
  cal.events.create(title: sen[], start: 9.days.ago, :end => 8.day.ago)
  puts "http://localhost:9292/calendars/#{cal.id}?api_key=#{customer.api_key}"
end

