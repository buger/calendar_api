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

Dir.glob('lib/models/**/*.rb') { |f| require File.expand_path(f) }
Dir.glob('lib/api/**/*.rb') { |f| require File.expand_path(f) }

require_relative "factories"

RSpec.configure do |config|
  def json_parse(response)
    json_object = JSON.parse(last_response.body)
    case json_object
    when Hash
      Hash[json_object.sort].symbolize_keys
    when Array
      json_object.map(&:symbolize_keys)
    else 
      json_object
    end
  end

  RSpec::Matchers.define :contain_events do |*events|
    match do |response|
      json_parse(response).size == events.size &&
      json_parse(response).zip(events).all? do |actual_event, expected_event|
        actual_event[:title] == expected_event[:title] &&
        Time.parse(actual_event[:start]) == Time.at(expected_event[:start]).utc.to_s &&
        Time.parse(actual_event[:end]) == Time.at(expected_event[:end]).utc.to_s
      end
    end
  end

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

