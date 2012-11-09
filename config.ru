$LOAD_PATH.unshift(File.dirname(__FILE__))
require "config/boot"

use Rack::Static, urls: ["/css", "/js", "/images"], root: "public"

run CalendarAPI

