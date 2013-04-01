namespace :import do
	desc "imports data from VCS website"
	task :vcs => :environment do
	require 'rubygems'
	require 'nokogiri'
	require 'open-uri'
	require 'mechanize'

agent = Mechanize.new
agent.idle_timeout = 0.9
#Load the page into Mechanize
page = agent.get("https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp?Tab=Projects&a=1")
#Define maximum number of pages
#Find the link with javascript, which shows the number of pages
m = page.link_with(:text => "move last").attributes['href'].to_s
#Parse the string from javascript down to page digits
max = m[35..m.index(')')-11].to_i
i = 1
max.times do
	agent.post("https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp", "Tab" => 'Projects', "X999whichpage" => i)
	page = agent.page.parser()
	a = 13
	while !page.css("td")[a].nil? do
		a += 7
	end
	b = (a-13)/7-1
	c = 13
	b.times do
		title = page.css("td")[c].text.to_s.encode("UTF-16BE", :invalid => :replace, :replace => "'").encode("UTF-8").gsub("\u0092", "'")
		country_name = page.css("td")[c+2].text.to_s
		project = Project.create!(:title => title)
		project.countries.build(:name => country_name)
		project.standards.build(:name => 'VCS')
		project.save!
		c += 7
	end
	i += 1
end
end
end