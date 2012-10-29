$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "mongo_mapper"
require "grape"

require "rack/test"
require "database_cleaner"
require "factory_girl"

require "pry"
require "pry-nav"
require "pry-remote"

MongoMapper.database = "calendar_api"

Dir.glob('spec/support/**/*.rb') { |f| require File.expand_path(f) }
Dir.glob('lib/models/**/*.rb') { |f| require File.expand_path(f) }
require File.expand_path("lib/api/helpers.rb")
require File.expand_path("lib/api/validators.rb")
Dir.glob('lib/api/**/*.rb') { |f| require File.expand_path(f) }

require_relative "factories"

RSpec.configure do |config|
  config.include RSpec::CustomMatchers

  config.include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner[:mongo_mapper].strategy = :truncation
    DatabaseCleaner[:mongo_mapper].clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner[:mongo_mapper].start
  end

  config.after(:each) do
    DatabaseCleaner[:mongo_mapper].clean
  end
end

