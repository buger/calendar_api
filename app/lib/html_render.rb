require "erb"

class HTMLRender
  def initialize(public_path, *objects)
    @public_folder = public_path
    @title, @description, @events = normalize(objects.flatten)
  end

  def render
    template = File.read("app/views/calendar.erb")
    ERB.new(template).result(binding)
  end

  private

  def normalize(objects)
    if objects.first.is_a?(Event)
      title  = objects.map { |o| o.calendar.title }.uniq.join(", ")
      events = objects

      [title, nil, events]
    elsif objects.first.is_a?(Calendar)
      title  = objects.map { |o| o.title }.uniq.join(", ")
      events = objects.map { |e| e.events }.flatten

      [title, nil, events]
    elsif objects.first.is_a?(Grape::Entity)
      title = objects.map { |o| o.object.title }.uniq.join(", ")

      events = []

      objects.each do |calendar|
        events += calendar.object.events if calendar.options[:with_events]
        events += calendar.object.holidays if calendar.options[:with_holidays]
      end

      [title, nil, events]
    else
      [nil, nil, nil]
    end
  end
end

