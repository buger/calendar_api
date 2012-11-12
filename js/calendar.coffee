MONTH_NAMES = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']
DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

data = [
    name: 'Leon'
    offset: - new Date().getTimezoneOffset() / 60
    availability: "13-23"
    country: 'RU'
,    
    name: 'Jeff Lawrence'
    offset: -6
    availability: "8-23"
    country: "CA"
,
    name: 'Shawn'
    offset: -6
    availability: "8-20"
    country: "CA"
,
    name: 'Vladimir Zheleznyak'
    offset: 3
    country: "UA"
,
    name: 'Adrian'
    offset: 3
    country: "RO"
,
    name: 'Luke'
    offset: -6
    availability: "8-17"
    country: "CA"
,
    name: 'Kyle'
    offset: -6
    availability: "8-17"
    days: [1,2,4]
    country: "CA" 
,
    name: 'Sergey'
    offset: 3
    country: "UA"
,
    name: 'Raresh'
    offset: 2
    availability: "15-21"
    country: "RO"
]

Date::stripTime = ->
     new Date @getFullYear(), @getMonth(), @getDate()


class @Calendar

    constructor: ->
        # getTimezoneOffset returns offset in minutes
        @current_user = data[0]

    setViewDate: (date) ->
        @date = date

    getZoneData: (data, offset) ->
        sorted = _.sortBy(data, (p) => @current_user.offset - p.offset)
        sorted.splice(0, 0, @current_user)

        sorted


    formatHour: (hour) ->
        if hour > 24
            hour - parseInt(hour/24)*24
        else if hour < 0
            24 + hour
        else if hour is 24
            0
        else
            hour


    isAvailableHour: (hour, availability) ->
        if availability
            availability = _(availability.split(',')).map((a) -> a.split('-'))
        else
            availability = [[10,20]]

        for a in availability
            if a.length > 1
                if hour >= a[0] and hour < a[1]
                    available = true
            else
                if hour is a[0]
                    available = true

        available


    isAvailableDay: (day, availability) ->
        if availability
            availability = []        


    drawZones: (date = @date) ->        
        zone_data = @getZoneData data, @current_user.offset

        hours = d3.range(0, 24*7, 1)    

        d3.select("#timezone_table").append("table")
            .attr("class", "table")
            .selectAll("tr")
            .data(zone_data)
        .enter().append("tr")
            .selectAll("td")
            .data((row, i) =>
                list = hours.map((h) => 
                    {
                        date: new Date(+date + h*3600*1000 - @current_user.offset * 3600 * 1000 + row.offset * 3600 * 1000 )
                        obj: row
                    }
                )
                list.splice(0, 0, row.name)
                list
            )
        .enter().append("td")
            .attr("class", (d,i) =>
                if i isnt 0                
                    hour = d.date.getHours()
                    classes = ["hour_#{hour}", "idx_#{i}"]

                    if @isAvailableHour hour, d.obj.availability
                        classes.push "available"
                    else
                        classes.push "dnd"

                    available_days = d.obj.days || [1,2,3,4,5]
                    unless _(available_days).include d.date.getDay()
                        classes.push "holiday"
                    else
                        classes.push "regular"

                    classes.join(' ')
            )        
            .on("mouseover", (d, i) ->            
                $("#timezone_table .idx_#{i}").addClass("selected")
            )
            .on("mouseout", (d, i) ->
                $("#timezone_table td.selected").removeClass("selected")
            )
            .append("div")
                .text((d, i) => 
                    if i
                        hour = d.date.getHours()

                        if hour is 0
                            MONTH_NAMES[d.date.getMonth()] + "\n" + d.date.getDate()
                        else
                            hour
                    else
                        d
                )
                .attr("title", (d,i) ->
                    if i
                        d.date.toString()
                    else 
                        d
                )

        $("#timezone_table .idx_1").addClass("selected")

    drawWeeks: (date = @date) ->
        $("#calendar").html('')

        date = date.stripTime()

        last_sunday = d3.time.sunday(date)

        days = d3.time.days(d3.time.sunday(date), last_sunday.setDate(last_sunday.getDate() + 7*6))

        formatDate = (date) -> date.toLocaleDateString()

        d3.select("#calendar")
            .selectAll('h2')
        .data([+days[0]]).enter()
            .append('h2')
            .html((d) -> "From <span>#{days[0].toLocaleDateString()}</span> to <span>#{days[days.length-1].toLocaleDateString()}</span><a id='next'>→</a><a id='prev'>←</a>")

        $('#next').unbind().click =>
            @drawWeeks(days[days.length-1])

        $('#prev').unbind().click =>
            days[0].setDate(days[0].getDate() - 7*6)

            @drawWeeks(days[0])

        d3.select("#calendar")
            .selectAll('div.header')
        .data(d3.range(0,7)).enter()
            .append('div')
            .attr('class', (d) -> 
                "header col_#{d}"
            )
            .text((d) => DAY_NAMES[d])


        d3.select("#calendar")
            .selectAll('div.day')        
        .data(days).enter()
            .append('div')
            .attr("class", (d, i) ->
                row = parseInt(i/7)
                col = i % 7

                classes = "day row_#{row} col_#{col}"
                classes += " current" if (+d) is (+date)
                classes += " #{+d}"

                classes                
            )
            .text (d) ->
                d.getDate()

        colors = d3.scale.category20()


        $('#calendar .holiday').remove()

        for idx, country of _.uniq(_.map(data, (el) -> el.country))
            for day in days
                do (day, country, idx) ->                    
                    Holidays.isHoliday day, country, (day_info) ->
                        if day_info
                            holiday = $('<a rel="tooltip" class="holiday"></a>')
                            holiday.attr('data-country', country)
                            holiday.attr('title', "#{countries[country].name} - #{day_info.name}")
                            holiday.attr('data-type', day_info.type)
                            holiday.css('background-color', colors(idx))
                            holiday.text(day_info.name)

                            holiday.tooltip()


                            if day_info.type in ['Muslim','Christian','Clock change/Daylight Saving Time','Observance','Orthodox','season','Jewish holiday','Local holiday','Season','Local observance']
                                holiday.hide()

                            $("#calendar .#{+day}").append holiday

