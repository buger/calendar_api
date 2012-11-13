$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'config'))

require "config/boot"

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

  sen = proc { Faker::Lorem.sentence[0..39] }

  customer = Customer.create
  cal = customer.calendars.create(title: sen[], country: "Russia")
  cal.events.create(title: sen[], start: 5.days.ago, :end => 1.day.ago)
  cal.events.create(title: sen[], start: 9.days.ago, :end => 8.day.ago)
  puts "http://localhost:9292/calendars/#{cal.id}?api_key=#{customer.api_key}"
  puts "http://localhost:9292/calendars/#{cal.id}.html?api_key=#{customer.api_key}&holidays=true"
end

desc "Load holidays"
task "holidays" do
  HolidayCalendar.all.each(&:destroy)
  customer = Customer.create
  Dir["data/holidays/**/*.json"].each do |json_file|
    holidays_hash = JSON.parse(File.read(json_file))
    holidays_list, country = holidays_hash.values_at("holidays", "country")

    holiday_model = HolidayCalendar.create(country: country)
    holiday_model.customer = customer
    holiday_model.save

    holidays_list.each do |holiday_event|
      time, holiday_name, description = holiday_event

      event = holiday_model.events.build
      event.start       = Time.at(time / 1000 + 6.hours.to_i).utc.to_i
      event.end         = Time.at(time / 1000 + 30.hours.to_i).utc.to_i
      event.title       = holiday_name
      event.description = description
      event.save
    end
  end
  puts "Holidays have been created"
  puts HolidayCalendar.all.map { |hc| "#{hc.country} (#{hc.events.count})" }.join(", ")
end

desc "console"
task "c" do
  `irb --prompt simple -I . -r config/boot`
end

