jQuery(document).ready(->
	$togle_control = $('.togle-control')
	$togle_control.addClass('clickable')
	$('.togle-content').hide()
	$togle_control.bind('click', ->
		$control = $(@)
		$parent = $control.parents('.togle-unit')
		$parent.toggleClass('expanded')
		$parent.find('.togle-content').slideToggle()
		if $parent.hasClass('expanded')
			$control.html($control.attr('data-expanded-text'))
		else
			$control.html($control.attr('data-text'))
	)
)

jQuery(".accordion").on "show hide", (e) -> 
  $(e.target).siblings(".accordion-heading").find(".accordion-toggle i").toggleClass "icon-chevron-down icon-chevron-right"