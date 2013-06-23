namespace :import do
  desc "imports data from external sources"
  task :vcs => :environment do
    require 'rubygems'
    require 'open-uri'
    require 'nokogiri'
    require 'mechanize'

agent = Mechanize.new
agent.idle_timeout = 0.9
agent.post('https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp', "X999field" => "Project ID", "X999sort" => "Desc", "X999tablenumber" => "2")
max = page.search("html body div#wrapper.project-list div#content div#content-inner div#main.clearfix div#projectList.qtable form#xxxx2 table tr[2] td[1]")[0].text.to_s

link = "https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp?Tab=Projects&a=2&i="
i = 0

max.times do
	vcs_url = link + i.to_s
	
	agent.get(vcs_url)
	agent.page.encoding = 'ISO-8859-1'
	agent.page.encoding = 'cp1252'
	title_plus_country = agent.page.search("h1").text.encode!("utf-8", "utf-8", :invalid => :replace)
	country = agent.page.search(".country").text.encode!("utf-8", "utf-8", :invalid => :replace)
	title = title_plus_country.sub(", " + country, "")
	
    #Create a new project record
    project = Project.create!(:title => title, :refno => "i")
    #Write in the country names
    project.countries.build(:name => country)
    #Write the standard name
    project.standards.build(:name => 'VCS')
    #Save the database entries
    project.save!
	puts i.to_s + ". " + title + ", " + country
    i += 1 
	sleep 1
end
end
end