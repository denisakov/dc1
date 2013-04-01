namespace :import do
  desc "imports data from the project list on CDM website"
  task :cdm => :environment do
    require 'rubygems'
    require 'nokogiri'
    require 'open-uri'
    require 'mechanize'
  
  agent = Mechanize.new
  agent.idle_timeout = 0.9
  #Load the page into Mechanize
  agent.get("http://cdm.unfccc.int/Projects/projsearch.html")
  #Choose the second form on the page
  form = agent.page.forms[1]
  #Click "submit" button to see pages with all projects
  form.submit
  #Define maximum number of pages
  max = agent.page.links[63].text.to_i
  i = 0
    max.times do
      sleep 0.5
      agent.post('http://cdm.unfccc.int/Projects/projsearch.html', "page" => i)
      a = 1
      page = agent.page.parser()
      while !page.css("#projectsTable td")[a].nil? do
        #Retreave the project title
        title = page.css("#projectsTable td")[a].text.strip
        #Retreave the country name
        country_name = page.css("#projectsTable td")[a+1].text.strip
        #Create a new project record
        project = Project.create!(:title => title)
        #Write in the country names
        project.countries.build(:name => country_name)
        #Write the standard name
        project.standards.build(:name => 'CDM')
        #Save the database entries
        project.save!
        a = a + 7
        puts "#{project.id}, #{title}, #{country_name}"
      end
      i += 1
    end
  end
end