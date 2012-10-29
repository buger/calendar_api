require "grape"
require "mongo_mapper"
MongoMapper.database = "calendar_api"

Dir.glob('lib/models/**/*.rb') { |f| require File.expand_path(f) }
require File.expand_path("lib/api/application_api.rb")
Dir.glob('lib/api/**/*.rb') { |f| require File.expand_path(f) }

run CalendarAPI

