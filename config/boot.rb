require "grape"
require "mongo_mapper"

MongoMapper.database = "calendar_api"

Dir["app/{api,lib,models}/**/*.rb"].sort.each { |f| require File.expand_path(f) }

