module RSpec
  module Helpers
    def mash(hash)
      Hashie::Mash[hash]
    end

    def holidays_for(calendar)
      Holidays.for_country(calendar.country)
    end
  end
end

