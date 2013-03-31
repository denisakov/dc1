namespace :import do
	desc "imports data from VCS website"
	task :vcs => :environment do
	require 'rubygems'
	require 'nokogiri'
	require 'open-uri'

html = open("https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp?Tab=Projects&a=1", "r:ISO-8859-1:UTF-8")
doc = Nokogiri::HTML(html.read)
counter = 2
hash_for_store = Hash.new
row_part_of_css_tag = 'tr:nth-child('
column_for_country_name_in_css_tag = ') td:nth-child(4)'
column_for_project_name_in_css_tag = ') td:nth-child(2)'
50.times {
	row_counter_in_css_tag = counter.to_s
	final_css_tag_for_country_name = row_part_of_css_tag + row_counter_in_css_tag + column_for_country_name_in_css_tag
	final_css_tag_for_project_name = row_part_of_css_tag + row_counter_in_css_tag + column_for_project_name_in_css_tag
	country_name = doc.css(final_css_tag_for_country_name).text
	project_name = doc.css(final_css_tag_for_project_name).text
	hash_for_store[project_name] = country_name
	counter = counter + 1
}
hash_for_store.each { |key,value|
	new_project_in_db = Project.new
	new_project_in_db.title = key #.encode("UTF-16BE", :invalid => :replace, :replace => "?").encode("UTF-8").gsub("\u0092", "?")
	new_project_in_db.countries.build(:name => value)
	new_project_in_db.standards.build(:name => 'VCS')
	new_project_in_db.save!
}
end
end