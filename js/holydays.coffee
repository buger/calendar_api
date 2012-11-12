@countries = {
    'RU': {
        'name': 'Russian Federation'
        'code': 'russia'
    }
    'US': {
        'name': 'United States of America'
        'code': 'us'
    }
    'UA': {
        'name': 'Ukraine'
        'code': 'ukraine'
    }
    'CA': {
        'name': 'Canada'
        'code': 'canada'
    }
    'RO': {
        'name': 'Romania'
        'code': 'romania'
    }
    'UK': {
        'name': 'United Kingdom'
        'code': 'uk'
    }
}


#   Memoise for async functions
#   
#       func = async_memoise(func)
#
async_memoise = (func) ->
    memo = {}
    
    ->
        args = Array.prototype.slice.call(arguments)

        # We assume that function last argument is callback
        # 
        #    function(arg1, arg2, ..., callback)
        #    
        # If you have different func structure, code below should be changed
        key = args.slice()
        callback = key.splice(key.length-1, 1)[0]

        if memo[key]                        
            if typeof memo[key] is "function" # still waiting for data
                return memo[key].queue.push callback
            else
                return callback memo[key]

        # Building our own callback
        # When called it should call each callback in queu
        memo[key] = (resp) -> 
            f(resp) for f in memo[key].queue                 
            memo[key] = resp

        # Our original callback will be first in queue
        memo[key].queue = [ callback ]

        # Replacing original callback with ours
        args[args.length - 1] = memo[key]

        # calling original function
        func.apply @, args
        

class Holidays

    constructor: ->
        @getHolidays = async_memoise @getHolidays


    isHoliday: (date, country_code, callback) ->
        country = countries[country_code]
        year = date.getFullYear()
        date = date.stripTime()
        country.weekends ||= [0,6]


        @getHolidays country.code, year, (holidays) ->
            if date.getDay() in country.weekends and holidays[+date]?.type? != "Working day (moved weekend)"
                callback { name: "Weekends", type: "Weekends" }
            else if holidays[+date]
                callback holidays[+date] 
            else
                callback()                


    getHolidays: (country_code, year, callback) ->
        $.getJSON("/data/#{country_code}.#{year}.json")
            .success (data) =>
                holidays = {}

                for day in data.holidays
                    holidays[day[0]] = { name: day[1], type: day[2] }

                callback holidays
            .error =>
                callback {}


@Holidays = new Holidays