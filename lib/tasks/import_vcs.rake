namespace :import do
  desc "imports data from external sources"
  task :vcs => :environment do
    require 'rubygems'
    require 'open-uri'
    require 'nokogiri'
    require 'mechanize'

agent = Mechanize.new
agent.idle_timeout = 0.9
link = "https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp?Tab=Projects&a=2&i="
title = "dd"
i = 1

while (title != "") do
	url = link + i.to_s
	agent.get(url)
	agent.page.encoding = 'ISO-8859-1'
	agent.page.encoding = 'cp1252'
	title_plus_country = agent.page.search("h1").text.encode!("utf-8", "utf-8", :invalid => :replace)
	country = agent.page.search(".country").text.encode!("utf-8", "utf-8", :invalid => :replace)
	title = title_plus_country.sub(", " + country, "")
	
	if title != ""
	    #Create a new project record
	    project = Project.create!(:title => title)
	    #Write in the country names
	    project.countries.build(:name => country)
	    #Write the standard name
	    project.standards.build(:name => 'VCS')
	    #Save the database entries
	    project.save!
	end
	puts i.to_s + ". " + title + ", " + country
    i += 1 
	sleep 1
end
end
end