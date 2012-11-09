require "erb"

class HTMLRender
  def initialize(context)
    @title = context.title
    @description = context.description
    @events = context.send(:add_holidays, context.events)
  end

  def render
    template = File.read("app/views/calendar.erb")
    ERB.new(template).result(binding)
  end
end

