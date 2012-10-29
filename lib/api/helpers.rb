class CalendarAPI < Grape::API
  helpers do
    def location_for(resource)
      File.join @env["PATH_INFO"], resource.id
    end
  end
end

