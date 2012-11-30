require "spec_helper"
require "benchmark"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  let(:customer) { create(:customer) }
  let(:api_key) { { api_key: customer.api_key }.to_query }

  let!(:holiday_calendar1) { create(:holiday_calendar) }
  let!(:holiday_calendar2) { create(:holiday_calendar) }

  let(:calendar1) { create(:calendar, customer: customer, country: holiday_calendar1.country) }
  let(:calendar2) { create(:calendar, customer: customer, country: holiday_calendar2.country) }
  let(:calendar3) { create(:calendar, customer: customer, country: holiday_calendar1.country) }

  it "searches for the events" do
    [holiday_calendar1, holiday_calendar2].each do |holiday_calendar|
      30.times { create(:event, holiday_calendar: holiday_calendar) }
    end

    50.times { create(:calendar, customer: customer) }

    customer.calendars.each do |calendar|
      20.times { create(:event, calendar: calendar) }
    end

    calendar1 = customer.calendars[25]
    calendar2 = customer.calendars[15]
    calendar3 = customer.calendars[35]

    300.times { create(:event, calendar: calendar1) }

    %w(json ical html).each do |format|
      benchmark do
        get "/calendars/#{calendar1.id}/events.#{format}?#{api_key}"
      end
    end

    %w(json ical html).each do |format|
      benchmark do
        get "/calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events.#{format}?#{api_key}"
      end
    end

    puts "Holidays"

    %w(json ical html).each do |format|
      benchmark do
        get "/calendars/#{calendar1.id}/events.#{format}?#{api_key}&holidays=true"
      end
    end

    %w(json ical html).each do |format|
      benchmark do
        get "/calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events.#{format}?#{api_key}&holidays=true"
      end
    end
  end
end

def benchmark
  yield
  time = Benchmark.realtime { yield }
  puts "RUNTIME: #{time}"
end

