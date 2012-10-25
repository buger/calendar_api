$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "mongo_mapper"
require "grape"

require "rack/test"
require "database_cleaner"

require "pry"
require "pry-nav"
require "pry-remote"

MongoMapper.database = "calendar_api"

Dir.glob('lib/models/**/*.rb') { |f| require File.expand_path(f) }
Dir.glob('lib/api/**/*.rb') { |f| require File.expand_path(f) }

RSpec.configure do |config|
  def json_parse(response)
    json_object = JSON.parse(last_response.body)
    Hash === json_object ? Hash[json_object.sort] : json_object
  end

  config.include Rack::Test::Methods

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

