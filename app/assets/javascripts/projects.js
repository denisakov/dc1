$(document).ready(function() {
	var $togle_control = $('.togle-control');

	$togle_control.addClass('clickable');
	$('.togle-content').hide();

	$togle_control.bind('click', function() {
		var $control = $(this);
		var $parent = $control.parents('.togle-unit');

		$parent.toggleClass('expanded');
		$parent.find('.togle-content').slideToggle();

		// if control has HTML5 data attributes, use to update text
		if ($parent.hasClass('expanded')) {
			$control.html($control.attr('data-expanded-text'));
		} else {
			$control.html($control.attr('data-text'));
		}
	})
});

$(".accordion").on "show hide", (e) -> 
  $(e.target).siblings(".accordion-heading").find(".accordion-toggle i").toggleClass "icon-chevron-down and icon-chevron-right"