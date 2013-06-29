namespace :crawl do
  desc "collects and updates data from external sources"
  task :pages => :environment do
    require 'rubygems'
    require 'open-uri'
    require 'nokogiri'
    require 'mechanize'
    require 'timeout'

    @timed_out = Array.new
    @agent = Mechanize.new
	@agent.idle_timeout = 0.9

def cdm_update_page_crawler(webcrawls = Webcrawl.where(:source => "cdm_gsp", :status_code => 2))
 	puts "Updating the CDM pproject data"
	webcrawls.each do |crawl|
		begin
			cdm_proj_url = crawl.url
			base_html = crawl.html
			status = Timeout::timeout(20) {
				page_html = open(cdm_proj_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
				cdm_proj_page = Nokogiri::HTML(page_html)
				current_proj_html = cdm_proj_page.css("html body div#container div#content div#cols div#main")
		    	#Project data haven't changed
				if base_html == current_proj_html.to_html then
					puts "Nothing changed!"
					#Setting code to 2 for the update in the next run of the script
					crawl.status_code = 2
					#Since no timeouts occured resetting number of retries
					crawl.retries = 5
					crawl.touch
					crawl.save
				#There were changes in the project
				else
					puts "Need to update!"
					crawl.html = current_proj_html.to_html
					#Need to insert here what will happen with pages needing update

					#Setting code to 2 for the update in the next run of the script
					crawl.status_code = 2
					#Since no timeouts occured resetting number of retries
					crawl.retries = 5
					crawl.touch
					crawl.save
				end
			}
		#Timeout exception
		rescue Timeout::Error
			if crawl.retries > 0
				puts "The page seems to take longer than 20 seconds. We'll get back to it later."
				#Increase the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts crawl.url
				#Constant timeout status is 4
				crawl.status_code = 4
				crawl.touch
				crawl.save
			end
		end
	end
	if !@timed_out.empty? then
		puts "There were some timeouts."
		#Searching for the pages which had timedout
		webcrawls = Webcrawl.find(@timed_out)
		@timed_out = []
		#Calling the same method on the timed out pages
		cdm_update_page_crawler(webcrawls)
	#No timeouts
	else
		puts "Moving on."
	end
end

def cdm_new_page_crawler(webcrawls = Webcrawl.where(:source => "cdm_gsp", :status_code => 1))
 	puts "Collecting new CDM projects"
	webcrawls.each do |crawl|
		begin
			gsp_page_url = crawl.url
			status = Timeout::timeout(20) {
				page_html = open(gsp_page_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
				gsp_page = Nokogiri::HTML(page_html)
				@gsp_page_html = gsp_page.css("html body div#container div#content div#cols div#main")
				#Retrive the project ID and the Title
				cdm_proj_id_title = @gsp_page_html.css("div.mH div").text.strip.gsub( "\u0096", "-" )
				#Retrieve the project ID
				cdm_proj_id = cdm_proj_id_title[12..18].strip.prepend("CDM")
				#Retreave the project title
				cdm_proj_title = cdm_proj_id_title[cdm_proj_id_title.index(":")+1..cdm_proj_id_title.length].strip
				#Retreave the country name
				cdm_host_country = gsp_page.css("tr:nth-child(2) strong").text
				#Find if the scale is the number 5 or number 6
				if gsp_page.css("tr:nth-child(5) th").inner_text.strip == "Activity Scale"
					#Grab the project scale
					@cdm_proj_scale = gsp_page.css("tr:nth-child(5) td").text.capitalize
				else
					@cdm_proj_scale = gsp_page.css("tr:nth-child(6) td").text.capitalize
				end
				#Retreave the fee amount
				cdm_fee = gsp_page.css("tr:nth-child(8) span").text
				if cdm_fee.empty? then
					cdm_fee = gsp_page.css("tr:nth-child(9) span").text
				end
				#Create a new project record
				project = Project.create!(:title => cdm_proj_title, :refno => cdm_proj_id, :scale => @cdm_proj_scale, :fee => cdm_fee)
				#Write in the country names
				project.countries.build(:name => cdm_host_country)
				#Write the standard name
				project.standards.build(:name => 'Clean Development Mechanism', :short_name => 'CDM')
				#Save the database entries
				project.save!
				#Update the crawl record for the project page
				crawl.update_attributes(:html => @gsp_page_html.to_html, :project_id => project.id, :status_code => 2)
				crawl.touch
				crawl.save
				puts "#{cdm_proj_id}, #{cdm_proj_title}, #{cdm_host_country}, #{@cdm_proj_scale}, $#{cdm_fee}"
				
				associated_pages = Webcrawl.where("url like ?", "%#{gsp_page_url[0..-2]}%")
				associated_pages.each do |x|
					x.update_attributes(:project_id => project.id)
					puts "Associated pages updated with project id #{project.id}"
				end
				
			}
		rescue Timeout::Error
			if crawl.retries > 0
				puts "The page seems to take longer than 20 seconds. We'll get back to it later."
				#Increase the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts crawl.url
				#Constant timeout status is 4
				crawl.status_code = 4
				crawl.touch
				crawl.save
			end
		end
	end
	if !@timed_out.empty? then
		puts "There were some timeouts."
		#Selecting all pages with timeouts so far
		webcrawls = Webcrawl.find(@timed_out)
		#Calling the same method but only with the timed out pages
		cdm_update_page_crawler(webcrawls)
	#No timeouts
	else
		puts "Moving on."
	end
end

def vcs_update_page_crawler(webcrawls = Webcrawl.where(:source => "vcs", :status_code => 2))
	puts "Updating the VCS pproject data"
	webcrawls.each do |crawl|
		begin
			vcs_page_url = crawl.url
			base_html = crawl.html
			status = Timeout::timeout(20) {
				@agent.get(vcs_page_url)
				@agent.page.encoding = 'ISO-8859-1'
				@agent.page.encoding = 'cp1252'
				current_proj_html = @agent.page.search("html body div#wrapper.project-detail div#content div#content-inner div#main.clearfix").text.encode!("utf-8", "utf-8", :invalid => :replace)
				
				#Project data haven't changed
				if base_html == current_proj_html then
					puts "Nothing changed in #{crawl.id}"
					#Setting code to 2 for the update in the next run of the script
					crawl.status_code = 2
					#Since no timeouts occured resetting number of retries
					crawl.retries = 5
					crawl.touch
					crawl.save
				#There were changes in the project
				else
					puts "Need to update the project #{crawl.id}" 
					crawl.html = current_proj_html
					#Need to insert here what will happen with pages needing update

					#Setting code to 2 for the update in the next run of the script
					crawl.status_code = 2
					#Since no timeouts occured resetting number of retries
					crawl.retries = 5
					crawl.touch
					crawl.save
				end
			}
		rescue Timeout::Error
			if crawl.retries > 0
				puts "The page seems to take longer than 20 seconds. We'll get back to it later."
				#Increase the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts crawl.url
				#Constant timeout status is 4
				crawl.status_code = 4
				crawl.touch
				crawl.save
			end
		end
	end
	if !@timed_out.empty? then
		puts "There were some timeouts."
		#Selecting all pages with timeouts so far
		webcrawls = Webcrawl.find(@timed_out)
		#Empty the timeout for next time
		@timed_out = []
		#Calling the same method but only with the timed out pages
		vcs_update_page_crawler(webcrawls)
	#No timeouts
	else
		puts "Moving on."
	end
end

def vcs_new_page_crawler(webcrawls = Webcrawl.where(:source => "vcs", :status_code => 1))
	puts "Collecting new VCS pproject data"
	webcrawls.each do |crawl|
		begin
			vcs_page_url = crawl.url
			status = Timeout::timeout(20) {
				@agent.get(vcs_page_url)
				@agent.page.encoding = 'ISO-8859-1'
				@agent.page.encoding = 'cp1252'
				vcs_page_html = @agent.page.search("html body div#wrapper.project-detail div#content div#content-inner div#main.clearfix")
				
				title_plus_country = vcs_page_html.search("h1").text.encode!("utf-8", "utf-8", :invalid => :replace)
				vcs_host_country = vcs_page_html.search(".country").text.encode!("utf-8", "utf-8", :invalid => :replace)
				vcs_proj_title = title_plus_country.sub(", " + vcs_host_country, "")
				#Find the project reference number
				vcs_proj_id = "%.4i" %vcs_page_html.search("dd:nth-child(2)").text.delete("^0-9")
				#check if the project is empty record

				if !vcs_proj_title.empty? and !vcs_host_country.empty? and !vcs_proj_title.downcase.include? "error" then
					#Create a new project record
					project = Project.create!(:title => vcs_proj_title, :refno => vcs_proj_id)
					#Write in the country names
					project.countries.build(:name => vcs_host_country)
					#Write the standard name
					project.standards.build(:name => 'Verified Carbon Standard', :short_name => 'VCS')
					#Save the database entries
					project.save!
					vcs_page_html = vcs_page_html.text.encode!("utf-8", "utf-8", :invalid => :replace)
					crawl.update_attributes(:html => vcs_page_html, :project_id => project.id, :status_code => 2)
					crawl.touch
					crawl.save
					puts "#{vcs_proj_id}. #{vcs_proj_title} - #{vcs_host_country} - Project ID #{project.id}"
				else
					puts "#{vcs_proj_id}. #{vcs_proj_title} - #{vcs_host_country} - Erroneous or incomplete record"
				end
			}
		rescue Timeout::Error
			if crawl.retries > 0
				puts "The page seems to take longer than 20 seconds. We'll get back to it later."
				#Increase the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts crawl.url
				#Constant timeout status is 4
				crawl.status_code = 4
				crawl.touch
				crawl.save
			end
		end
	end
	if !@timed_out.empty? then
		puts "There were some timeouts."
		#Selecting all pages with timeouts so far
		webcrawls = Webcrawl.find(@timed_out)
		#Empty the timeout for next time
		@timed_out = []
		#Calling the same method but only with the timed out pages
		vcs_new_page_crawler(webcrawls)
	#No timeouts
	else
		puts "Moving on."
	end
end

def markit_update_page_crawler(webcrawls = Webcrawl.where(:source => "mark", :status_code => 2))
	puts "Updating Markit project data"
	webcrawls.each do |crawl|
		begin
			mark_page_url = crawl.url
			base_html = crawl.html
			status = Timeout::timeout(20) {
				current_proj_html = Nokogiri::HTML(open(mark_page_url))
				#Change the encoding twice to filter out incorrect symbols
				current_proj_html.encoding = "ISO-8859-1"
				current_proj_html.encoding = "cp1252"
				current_proj_html = current_proj_html.text.encode!("utf-8", "utf-8", :invalid => :replace)
				#Project data haven't changed
				if base_html == current_proj_html then
					puts "Nothing changed in #{crawl.url}"
					#Setting code to 2 for the update in the next run of the script
					crawl.status_code = 2
					#Since no timeouts occured resetting number of retries
					crawl.retries = 5
					crawl.touch
					crawl.save
				#There were changes in the project
				else
					puts "Need to update the project #{crawl.url}" 
					crawl.html = current_proj_html
					#Need to insert here what will happen with pages needing update

					#Setting code to 2 for the update in the next run of the script
					crawl.status_code = 2
					#Since no timeouts occured resetting number of retries
					crawl.retries = 5
					crawl.touch
					crawl.save
				end

			}
		rescue Timeout::Error
			if crawl.retries > 0
				puts "The page seems to take longer than 20 seconds. We'll get back to it later."
				#Increase the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts crawl.url
				#Constant timeout status is 4
				crawl.status_code = 4
				crawl.touch
				crawl.save
			end
		end
	end
	if !@timed_out.empty? then
		puts "There were some timeouts."
		#Selecting all pages with timeouts so far
		webcrawls = Webcrawl.find(@timed_out)
		#Empty the timeout for next time
		@timed_out = []
		#Calling the same method but only with the timed out pages
		mark_update_page_crawler(webcrawls)
	#No timeouts
	else
		puts "Moving on."
	end
end

def markit_new_page_crawler(webcrawls = Webcrawl.where(:source => "mark", :status_code => 1))
	puts "Collecting new Markit projects data"
	webcrawls.each do |crawl|
		begin
			puts "Starting on #{crawl.url}"
			mark_page_url = crawl.url
			status = Timeout::timeout(20) {
				mark_page_html = Nokogiri::HTML(open(mark_page_url))
					#puts "grabbed a page"
				#Change the encoding twice to filter out incorrect symbols
				mark_page_html.encoding = "ISO-8859-1"
				mark_page_html.encoding = "cp1252"
					#puts "changed the encoding"
				#Find the internal ID of the project
				id = mark_page_html.css("#project_id")
					#puts "grabbed the id"
				#Find the title of the project
				title = mark_page_html.xpath("/html/body/h1").text.sub(id.text,"").sub('*',"").strip
				#Check if the title and ID are missing
				if !title.empty? and !id.empty? then
				#Find the full location of the project
				location = mark_page_html.css(".unitTable tr:nth-child(3) td").text
				if !location.index(',').nil? then
					#Extract the country name from location
					country = location.reverse[0..location.reverse.index(',')-1].reverse.strip
				else
					country = "Unknown"
				end
				#Find the name of the standard
				standard = mark_page_html.css(".unitTable tr:nth-child(2) td:nth-child(2)").text.strip
				#Identify which standard it is to see which short name to use
				short_standard = standard
				if standard == "Gold Standard"
					short_standard = "GS"
				end
				if standard == "Social Carbon"
					short_standard = "SC"
				end
				if standard == "Verified Carbon Standard"
					short_standard = "VCS"
				end
				#Find the project reference number
				proj_id = id.text.delete "(ID: )"
					#puts proj_id
				#Create a new project record
				project = Project.create!(:title => title, :refno => proj_id)
				#Write in the country names
				project.countries.build(:name => country)
				#Write the standard name
				project.standards.build(:name => standard, :short_name => short_standard)
				#Grab the list of mark_page_htmluments and loop throu it recording the titles and links
				mark_page_html.css(".doc").each do |d|
					doc_url = d['href'].strip.prepend("http://mer.markit.com")
					#Find the document id
					#doc_id = doc_url.reverse[0..14].reverse.prepend(" - ")
					#Find the title of the document
					doc_title = d.children.text
					#Ammend the title of the document with ID at the end (for control purposes)
					#doc_title = doc_id.prepend(d.children.text)
					#Write project url into the database
					project.documents.build(:title => doc_title, :issue_date => "01.01.2000", :link => doc_url)
				end
				#Save the database entries
				project.save!
				
				mark_page_html = mark_page_html.text.encode!("utf-8", "utf-8", :invalid => :replace)
				crawl.update_attributes(:html => mark_page_html, :project_id => project.id, :status_code => 2)
				crawl.touch
				crawl.save
				puts "#{proj_id} - #{title} - #{country}"
				project.documents.each do |d|
					puts "#{d.id} #{d.title}"
				end
			}
		rescue Timeout::Error
			if crawl.retries > 0
				puts "The page seems to take longer than 20 seconds. We'll get back to it later."
				#Increase the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts crawl.url
				#Constant timeout status is 4
				crawl.status_code = 4
				crawl.touch
				crawl.save
			end
		end
	end
	if !@timed_out.empty? then
		puts "There were some timeouts."
		#Selecting all pages with timeouts so far
		webcrawls = Webcrawl.find(@timed_out)
		#Empty the timeout for next time
		@timed_out = []
		#Calling the same method but only with the timed out pages
		mark_new_page_crawler(webcrawls)
	#No timeouts
	else
		puts "Moving on."
	end
end

#vcs_update_page_crawler
#vcs_new_page_crawler
markit_update_page_crawler
markit_new_page_crawler
#cdm_new_page_crawler
#cdm_update_page_crawler

if !Webcrawl.where(:status_code => 4).empty? then
	puts "These pages have timedout too many times. Check them manually, please!"
	puts "CDM"
	puts Webcrawl.where(:source => "cdm_gsp", :status_code => 4)
	puts "VCS"
	puts Webcrawl.where(:source => "vcs", :status_code => 4)
	puts "Markit"
	puts Webcrawl.where(:source => "mark", :status_code => 4)
end
end
end