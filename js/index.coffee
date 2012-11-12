$('.date input').datepicker()

$('form.request .date li a').on 'click', (evt) ->	
	$(@).parents('.btn-group').find('button .current').html(@.innerHTML)

$('form.request .type .btn').on 'click', (evt) ->	
	$(@).parents('.type').find('.btn').removeClass('btn-warning btn-success btn-info')
