require "json"
require "active_support/time"
require "active_support/core_ext/numeric"
require "active_support/core_ext/integer"

module Holidays
  Container ||= begin
    year = Time.now.year
    holidays = {}

    Dir["data/holidays/#{year}/*.json"].each do |json_file|
      holidays_hash = JSON.parse(File.read(json_file))
      holidays_list, country = holidays_hash.values_at("holidays", "country")

      holidays[country] = holidays_list.map do |holiday|
        event = Struct.new(:dtstart, :dtend, :description, :title).new

        time, holiday_name, description = holiday

        event.dtstart       = Time.at(time / 1000 + 6.hours.to_i).utc
        event.dtend         = Time.at(time / 1000 + 30.hours.to_i).utc
        event.title         = holiday_name
        event.description = description
        event
      end
    end

    holidays
  end

  def self.for_country(country)
    Container[country]
  end
end
