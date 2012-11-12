calendar = null

QUnit.testStart -> calendar = new Calendar


module "Date functions"
test "Date strip time", ->
    date = new Date

    strippedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

    equal +date.stripTime(), +strippedDate



module "Calendar utils"

test "Calendar format hour", ->
    equal calendar.formatHour(25), 1, "overflow"
    equal calendar.formatHour(-1), 23, "negative"
    equal calendar.formatHour(24), 0, "midnight"
    equal calendar.formatHour(16), 16, "normal"


test "Availabe hour, default", ->
    ok calendar.isAvailableHour(11), "default available"
    ok !calendar.isAvailableHour(9), "default dnd"

    ok calendar.isAvailableHour(19), "default available evening"
    ok !calendar.isAvailableHour(21), "default dnd evening"


test "Availabe hour, range", ->
    range = "10-17"

    ok calendar.isAvailableHour(11, range)
    ok !calendar.isAvailableHour(9, range)
    ok !calendar.isAvailableHour(17, range)

test "Availabe hour, multiple-range", ->
    range = "10-13,14-18"
    
    ok calendar.isAvailableHour(11, range)
    ok !calendar.isAvailableHour(13, range)
    ok calendar.isAvailableHour(15, range)



module "Holidays"
test "Should know holiday", ->
    stop()

    finished = _.after 7, -> start()

    Holidays.isHoliday new Date(2012, 0, 1), 'RU', (name) ->
        equal name, "New Year's Day"
        finished()
        
    Holidays.isHoliday new Date(2012, 0, 9), 'RU', (name) ->
        equal name, "New Year Holiday Week", "Holiday moved from weekends"
        finished()

    Holidays.isHoliday new Date(2012, 0, 11), 'RU' , (name) ->        
        ok name is undefined, "Work day"
        finished()

    Holidays.isHoliday new Date(2012, 0, 14), 'RU', (name) ->
        equal name, "Old New Year"
        finished()

    Holidays.isHoliday new Date(2012, 0, 15), 'RU', (name) ->
        equal name, "Weekends"
        finished()

    Holidays.isHoliday new Date(2012, 0, 16), 'RU', (name) ->
        equal name, undefined, "Work day"
        finished()


    Holidays.isHoliday new Date(2012, 4, 1), 'UA', (name) ->
        equal name, "National Labour Day"
        finished()
    



test "Computed holidays", ->
    stop()

    finished = _.after 6, -> start()

    Holidays.isHoliday new Date(2012, 3, 14), 'UA', (name) -> 
        equal name, "Weekends"
        finished()

    Holidays.isHoliday new Date(2012, 3, 15), 'UA', (name) ->
        equal name, "Orthodox Christian Easter"
        finished()

    Holidays.isHoliday new Date(2012, 3, 16), 'UA', (name) ->
        equal name, "Orthodox Christian Easter"
        finished()

    Holidays.isHoliday new Date(2012, 5, 3), 'UA', (name) ->
        equal name, "Orthodox Pentecost"
        finished()

    Holidays.isHoliday new Date(2012, 5, 4), 'UA', (name) ->
        equal name, "Orthodox Pentecost"
        finished()

    Holidays.isHoliday new Date(2012, 5, 5), 'UA', (name) ->
        equal name, undefined
        finished()


test "Computed holidays, returns date", ->
    stop()

    finished = _.after 2, -> start()

    Holidays.isHoliday new Date(2014, 8, 1), 'CA', (name) ->
        equal name, "Labour Day"
        finished()

    Holidays.isHoliday new Date(2012, 8, 3), 'CA', (name) ->
        equal name, "Labour Day"
        finished()

###
test "Print Ukraine holidays", ->
    years = [2010,2011,2012,2013,2014]

    for year in years
        holidays = []

        for name, day of Holidays.list()['UA']
            if typeof day is "function"
                try
                    day = day(new Date(year, 1, 1))
                catch e
                    day = 'undefined'

            [day, length] = day.split('-')
            length ?= 1
            length = parseInt(length)
                
            date = +Holidays.genDate(day, new Date(year, 1, 1))

            continue if isNaN(date)

            for l in [1..length]
                holidays.push [date, name, "National holiday"]

        console.warn year, JSON.stringify(holidays)
###