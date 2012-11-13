require "grape"
require "mongoid"

$CALENDAR_API_ROOT = Dir.pwd

Mongoid.load!("config/mongoid.yml", :development)
Mongoid.logger = Logger.new($stdout)

Dir["app/{api,lib,models}/**/*.rb"].sort.each { |f| require File.expand_path(f) }

