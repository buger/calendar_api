$('.date input').datepicker()

$('form.request .date li a').on 'click', (evt) ->	
	$(@).parents('.btn-group').find('button .current').html(@.innerHTML)

$('form.request .type .btn').on 'click', (evt) ->	
	$(@).parents('.type').find('.btn').removeClass('btn-warning btn-success btn-danger')

	map = 
		'vacation': 'btn-success'
		'personal': 'btn-warning'
		'sick': 'btn-danger'

	for key, value of map
		if $(@).hasClass key
			$(@).addClass map[key]
