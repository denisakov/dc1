namespace :import do
  desc "imports data from the project list on CDM website"
  task :cdm => :environment do
    require 'rubygems'
    require 'nokogiri'
    require 'open-uri'
    require 'mechanize'
  
    cdm_agent = Mechanize.new
    cdm_agent.idle_timeout = 0.9
    #Load the page into Mechanize
    cdm_agent.get("http://cdm.unfccc.int/Projects/projsearch.html")
    #Choose the second form on the page
    form = cdm_agent.page.forms[1]
    #Click "submit" button to see pages with all projects
    form.submit
    #Define maximum number of pages, by scanning
    max = cdm_agent.page.links[63].text.to_i
    i = 0
    max.times do
      cdm_agent.post('http://cdm.unfccc.int/Projects/projsearch.html', "page" => i)
      sleep = 0.5
      page = cdm_agent.page.parser()
      #Grab all project links on the page and visit each one individually
      page.css("#projectsTable td:nth-child(2) a").each do |p|
        #Define individual link
        cdm_proj_url = p['href'] + "?cp=1"
        #Grab the project page with Nokogiri
        cdm_proj_page = Nokogiri::HTML(open(cdm_proj_url))
        #Retrive the project ID and the Title
        cdm_proj_id_title = cdm_proj_page.css("html body div#container div#content div#cols div#main div.mH div").text.strip.gsub( "\u0096", "-" )
        #Retrieve the project ID
        cdm_proj_id = cdm_proj_id_title[12..18].strip
        #Retreave the project title
        cdm_proj_title = cdm_proj_id_title[cdm_proj_id_title.index(":")+1..cdm_proj_id_title.length].strip
        #Retreave the country name
        cdm_host_country = cdm_proj_page.css("tr:nth-child(2) strong").text
        #Retreave the fee amount
        cdm_fee = cdm_proj_page.css("tr:nth-child(8) span").text
        #Create a new project record
        project = Project.create!(:title => cdm_proj_title, :refno => cdm_proj_id, :fee => cdm_fee)
        #Write in the country names
        project.countries.build(:name => cdm_host_country)
        #Write the standard name
        project.standards.build(:name => 'CDM')
        #Save the database entries
        project.save!
        puts "#{project.refno}, #{cdm_proj_title}, #{cdm_host_country}, #{cdm_fee}"
      end
      i += 1
    end
  end
end