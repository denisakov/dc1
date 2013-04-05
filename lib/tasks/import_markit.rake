namespace :import do
  desc "imports data from Markit registry"
  task :markit => :environment do
    require 'rubygems'
    require 'open-uri'
    require 'nokogiri'

pre_link = "http://mer.markit.com/br-reg/public/index.jsp?p="
page_no= 1
post_link = "&r=&u=&scolumn=project_name&sdir=ASC&s=cp&q="

doc = Nokogiri::HTML(open("http://mer.markit.com/br-reg/public/index.jsp?p=1&r=&u=&scolumn=project_name&sdir=ASC&s=cp&q="))
p = doc.css("#public-search-page").inner_text.delete "Page"
top_page = p.reverse[0..p.reverse.index(' ')-1].reverse.strip.to_s

proj_link = "http://mer.markit.com/br-reg/public/project.jsp?project_id="

top_page.to_i.times do
table_link = pre_link + page_no.to_s + post_link
doc = Nokogiri::HTML(open(table_link))
doc.css("#public-view-results a").each do |a|
proj_id = a['href'][23..48].strip

#Construct the full link
proj_url = proj_link + proj_id.to_s
#Load the document into Nokogiri
doc = Nokogiri::HTML(open(proj_url))
#Change the encoding twice to filter out incorrect symbols
doc.encoding = "ISO-8859-1"
doc.encoding = "cp1252"
#Find the internal ID of the project
id = doc.css("#project_id")
#Find the title of the project
title = doc.xpath("/html/body/h1").text.sub(id.text,"").sub('*',"").strip
#id = doc.css("#project_id").text.delete "(ID: )"
#Find the full location of the project
location = doc.css(".unitTable tr:nth-child(3) td").text
#Extract the country name from location
country = location.reverse[0..location.reverse.index(',')-1].reverse.strip
#Find the name of the standard
standard = doc.css(".unitTable tr:nth-child(2) td:nth-child(2)").text.strip
#Create a new project record
project = Project.create!(:title => title)
#Write in the country names
project.countries.build(:name => country)
#Write the standard name
project.standards.build(:name => 'VCS')
#Save the database entries
project.save!
puts "#{proj_id} - #{title} - #{country} - #{standard}"
sleep 1
end
page_no += 1
end

end
end