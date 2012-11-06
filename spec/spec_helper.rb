$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "config"))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "support"))

require "pry"

require "rack/test"
require "database_cleaner"
require "factory_girl"

require "pry"
require "pry-nav"
require "pry-remote"

require "boot"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

require "factories"

RSpec.configure do |config|
  config.include RSpec::Helpers
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

