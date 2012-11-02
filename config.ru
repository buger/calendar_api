require "grape"
require "mongo_mapper"
MongoMapper.database = "calendar_api"

Dir.glob('lib/models/**/*.rb') { |f| require File.expand_path(f) }
require File.expand_path("lib/api/validators.rb")
require File.expand_path("lib/api/helpers.rb")
Dir.glob('lib/api/**/*.rb') { |f| require File.expand_path(f) }

run CalendarAPI

