require "grape"
require "mongoid"

Mongoid.load!("config/mongoid.yml", :development)
Mongoid.logger = Logger.new($stdout)

Dir["app/{api,lib,models}/**/*.rb"].sort.each { |f| require File.expand_path(f) }

