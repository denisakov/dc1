module ApplicationHelper
	def sortable(column, title = nil)
		title ||= column.titleize

		direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"

		if column == "c_name"
			direction = column == "c_name" && sort_direction == "asc" ? "desc" : "asc"
		end

		link_to "#{title} <i class='#{direction.present? && direction == "desc" ? "icon-chevron-down" : "icon-chevron-up"}'></i>".html_safe, {:sort => column, :direction => direction}
	end
end

# module ApplicationHelper
# 	def sortable(column, title = nil)
# 		title ||= column.titleize
# 		css_class = column == sort_column ? "current #{sort_direction}" :nil
# 		direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
# 		link_to title, {:sort => column, :direction => direction}, {:class => css_class}
# 	end
# end