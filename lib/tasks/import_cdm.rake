namespace :import_cdm do
  desc "imports data from external sources"
  task :data => :environment do
    require 'rubygems'
    require 'roo'
    require 'nokogiri'
    require 'open-uri'
    require 'mechanize'
    agent = Mechanize.new
  
  agent.get("http://cdm.unfccc.int/Projects/projsearch.html")
  form = agent.page.forms[1]
  form.submit
  agent.page.search("#projectsTable td:nth-child(2)").map(&:text).map(&:strip)
  agent.page.search("#projectsTable td:nth-child(2)").map(&:text).map(&:strip)
  agent.page.search("td:nth-child(3)").map(&:text).map(&:strip)
  agent.page.search("tr:nth-child(4) td:nth-child(3)").map(&:text).map(&:strip)
  
  agent.page.search("#projectsTable td:nth-child(2)").each do |x|
    Project.create!(:title => x.text.strip)
  end
  agent.page.search("#projectsTable td:nth-child(3)").each do |x|

  end  
end