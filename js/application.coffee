calendar = new Calendar
calendar.setViewDate new Date()


$("a[href=#hour_view]").click ->
    $('.navbar .active').removeClass('active')
    $(@).parent().addClass('active')

    calendar.drawZones() unless $('#timezone_table table').length

    $('#calendar').hide()
    $('#timezone_table').show()

    false


$("a[href=#week_view]").click -> 
    $('.navbar .active').removeClass('active')
    $(@).parent().addClass('active')

    calendar.drawWeeks() unless $('#calendar div.header').length

    $('#calendar').show()
    $('#timezone_table').hide()

    false

$("a[href=#week_view]").trigger("click")