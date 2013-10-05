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

def cdm_update_page_crawler(webcrawls = Webcrawl.where(:source => ["cdm_gsp","cdm_cp2","cdm_cp3"], :status_code => 2))
 	puts "Updating the CDM project data"
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
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

def cdm_new_page_crawler(webcrawls = Webcrawl.where(:source => ["cdm_gsp","cdm_cp2","cdm_cp3"], :status_code => 1))
 	puts "Collecting new CDM projects"
	webcrawls.each do |crawl|
		begin
			gsp_page_url = crawl.url

			status = Timeout::timeout(20) {

			if gsp_page_url =~ /cp=1/ then
				
				puts "Started"
				page_html = open(gsp_page_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
				gsp_page = Nokogiri::HTML(page_html)
				gsp_page_html = gsp_page.css("html body div#container div#content div#cols div#main")
				#Retrive the project ID and the Title
				cdm_proj_id_title = gsp_page_html.css("div.mH div").text.strip.gsub( "\u0096", "-" )
				#Retrieve the project ID
				cdm_proj_id = cdm_proj_id_title[12..18].strip
				#Retreave the project title
				cdm_proj_title = cdm_proj_id_title[cdm_proj_id_title.index(":")+1..cdm_proj_id_title.length].strip

				#Find if the scale is the number 5 or number 6
				if gsp_page_html.css("tr:nth-child(5) th").inner_text.strip == "Activity Scale"
					#Grab the project scale
					cdm_proj_scale = gsp_page_html.css("tr:nth-child(5) td").text.strip.capitalize!
				else
					cdm_proj_scale = gsp_page_html.css("tr:nth-child(6) td").text.strip.capitalize!
				end
				#Retreave the fee amount
				cdm_fee = gsp_page_html.css("tr:nth-child(8) span").text
				if cdm_fee.empty? then
					cdm_fee = gsp_page_html.css("tr:nth-child(9) span").text
				end
				#Create a new project record
				project = Project.create!(:title => cdm_proj_title, :refno => cdm_proj_id, :scale => cdm_proj_scale, :fee => cdm_fee)
				puts "created a project"
				std_name = "Clean Development Mechanism"
				short_std_name = "CDM"
				#Write the standard name
				standard = Standard.create(:name => std_name, :short_name => short_std_name, :project_id => project.id)

				puts "#{cdm_proj_id}, #{cdm_proj_title}, #{cdm_proj_scale}, $#{cdm_fee}"
				
				#Analyse the block of "Host country"
				gsp_page_html.css("tr:nth-child(2)").children[2].children.each do |a|
					if !a.text.strip.empty? then
						#Retreave the country name
						cdm_host_country = a.children[1].text
						puts "Host country is #{cdm_host_country}"
						#Grab the first link from "approval"; ignoring the "authorization" for now, because they are mostly the same
						doc_url = a.children[3]['href']

						#set the role variable
						role = "Host"
						#set the process variable
						process_type = "Registration"
						#set the doc title; including the country name into doc's name for now.
						doc_title = "Letter of Approval"
						#set document short name
						short_doc_title = "LoA"
						#Define the issue date of the document
						issue_date = "01.01.2000"
						#Check if date exists
						date = WhenDate.where('date = ?', issue_date).first
						#Write in the new date or return the one found above
						date ||= WhenDate.create!(:date => issue_date)

						#Check if country name exists
						@country = Country.where('name = ?', cdm_host_country).first
						#Write in the new country names or return the one found above
						@country ||= Country.create!(:name => cdm_host_country)
						#Create a role for the country in the project
						project.roles.build(:country_id => @country.id, :role => role)						
						project.save!
						#Grab all the project participants
						host_pps = a.children[10].text.gsub(/Authorized Participants:/, '').strip.split(%r{;\s*})

						role = "host_pp"
						define_pp(@country, project, role, host_pps)

						#Find registering DOE
						short_doe_name = gsp_page_url.gsub("http://cdm.unfccc.int/Projects/DB/", "").gsub("/view?cp=", "").gsub(/[\d]/,"").gsub("%", " ").gsub(".","")
						doe_name_finder(short_doe_name)
						doe_name = @a[1]

						#Identify the stakeholder
						stakeholder = Stakeholder.where('title = ?', doe_name).first

						#Define the role of the Stakeholder in the project
						role = "val_doe"

						puts "#{stakeholder.id} #{doe_name} #{role}"

						project.entities.build(:project_id => project.id, :stakeholder_id => stakeholder.id, :role => role)

						#Create a document
						document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)

						#Create an occasion for the date in the project, country, document and standard
						project.occasions.build(:description => "Issue date", :country_id => @country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
						
						project.save!
						puts "Host country is #{@country.name}"
					end
				end
				#Grab the PDD and related docs
				gsp_page_html.css("tr:nth-child(1)").children[2].children.each do |a|
					if a['href'] =~ /FileStorage/ then
						doc_url = a['href']
						#set the doc title; including the country name into doc's name for now.
						doc_title = a.inner_text
						#set document short name
						short_doc_title = ""
					end
					if a.inner_text =~ /project design document/ then
						doc_url = a['href']
						#set the doc title; including the country name into doc's name for now.
						doc_title = "Project Design Document"
						#set document short name
						short_doc_title = "PDD"
					end
					if a.inner_text =~ /registration request form/ then
						doc_url = a['href']
						#set the doc title; including the country name into doc's name for now.
						doc_title = "Registration Request Form"
						#set document short name
						short_doc_title = "RegForm"
					end
					#set the process variable
					process_type = "Registration"
					if doc_title and doc_url then
						if a.inner_text =~ /accepted/ then
							new_pdd_acc_date = Date.parse(a.next.next.inner_text)

							#Check if date exists
							date = WhenDate.where('date = ?', new_pdd_acc_date).first
							#Write in the new date or return the one found above
							date ||= WhenDate.create!(:date => new_pdd_acc_date)
							#Create a document
							document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)
							#Create an occasion for the date in the project, country, document and standard
							project.occasions.build(:description => "PDD was accepted by CDM EB", :country_id => @country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
							project.save!

						end
						#Define the issue date of the document
						issue_date = "01.01.2000"
						#Check if date exists
						date = WhenDate.where('date = ?', issue_date).first
						#Write in the new date or return the one found above
						date ||= WhenDate.create!(:date => issue_date)
						#Create a document
						document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)
						#Create an occasion for the date in the project, country, document and standard
						project.occasions.build(:description => "Issue date", :country_id => @country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
						project.save!

						puts "#{doc_title}"
						puts "#{doc_url}"
					end
				end
				
				#Analyse the block of "Annex-I country"
				if gsp_page_html.css("tr:nth-child(3)").children[2].children.text.strip != "n/a" then
					#Grab the block with the investor country's info
					gsp_page_html.css("tr:nth-child(3)").children[2].children.each do |a|
						#Some of the elements will be nil, so need to check
						if !a.text.strip.empty? then
							#Define the investor country name
							cdm_inv_country = a.children[1].text
							#Special check for Canada, because it has withdrawn from KP
							if !cdm_inv_country.index(/[,.]/).nil? then
								cdm_inv_country = cdm_inv_country[0..cdm_inv_country.index(/[,.]/)-1]
							end
							#Define if the country involved directly or not, UNUSED FOR NOW IN DATABASE
							if a.text.strip =~ /involved/ then
								if a.text.strip =~ /indirectly/
									inv_country_role = "indirectly"
								else
									inv_country_role = "directly"
								end
							end
							inv_country_role ||= "Unknown"
							#Define the role of the country
							country_role = "Investor"
							#set the process variable
							process_type = "Registration"
							#set the doc title; including the country name into doc's name for now.
							doc_title = "Letter of Approval"
							#set document short name
							short_doc_title = "LoA"
							#Grab the first link from "approval"; ignoring the "authorization" for now, because they are mostly the same
							doc_url = a.children[5]['href']
							#Define the issue date of the document
							issue_date = "01.01.2000"
							#Check if date exists
							date = WhenDate.where('date = ?', issue_date).first
							#Write in the new date or return the one found above
							date ||= WhenDate.create!(:date => issue_date)

							#Check if country name exists
							country = Country.where('name like ?', cdm_inv_country).first
							#Write in the new country names or return the one found above
							country ||= Country.create!(:name => cdm_inv_country)

							#Create a role for the country in the project
							project.roles.build(:country_id => country.id, :role => country_role)

							#Idenfify the project participants
							if a.children[10] then
								#Grab all the project participants
								host_pps = a.children[10].text.gsub(/Authorized Participants:/, '').strip.split(%r{;\s*})
							else
								host_pps = a.children[8].text.gsub(/Authorized Participants:/, '').strip.split(%r{;\s*})
							end

							pp_role = "a1_pp"
							define_pp(country, project, pp_role, host_pps)

							
							#Create a document
							document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)

							#Create an occasion for the date in the project, country, document and standard
							project.occasions.build(:description => "Issue date", :country_id => country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)

							project.save!
							puts "Investor country is #{country.name}"
						end
					end
				end
			end

			if gsp_page_url =~ /cp=2/ then
				#
				next
			end

			if gsp_page_url =~ /cp=3/ then
				#
				next
			end

			#Update the crawl record for the project page
			crawl.update_attributes(:html => gsp_page_html.to_html, :project_id => project.id, :status_code => 2)
			crawl.touch
			crawl.save
			
			associated_pages = Webcrawl.where('url like ?', "%#{gsp_page_url[0..-2]}%")
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The page is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The page is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
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
				puts "Starting with the project #{vcs_proj_id}"
				if !vcs_proj_title.empty? and !vcs_host_country.empty? and !vcs_proj_title.downcase.include? "error" then
					#Create a new project record
					project = Project.create!(:title => vcs_proj_title, :refno => vcs_proj_id)
					#Check if country name exists
					country = Country.where('name = ?', vcs_host_country).first
					#Write in the new country names or return the one found above
					country ||= Country.create(:name => vcs_host_country)
					role = "Host"
					#Create a role for the country in the project
					project.roles.build(:country_id => country.id, :role => role)
					#Save the database entries
					project.save!

					std_name = "Verified Carbon Standard"
					short_std_name = "VCS"
					#Write the standard name
					standard = Standard.create(:name => std_name, :short_name => short_std_name, :project_id => project.id)
					
					issue_date = "01.01.2000"
					
					if !vcs_page_html.search("td:nth-child(1) a").empty? then
						#Set the process type
						process_type = "Registration"
						#Grab all registration documents
						vcs_page_html.search("td:nth-child(1) a").each do |d|
							#Find the document's URL
							doc_url = d['href'].strip.prepend("https://vcsprojectdatabase2.apx.com")
							#Find the title of the document
							doc_title = d.inner_text
							short_doc_title = ""
							#Check if date exists
							date = WhenDate.where('date = ?', issue_date).first
							#Write in the new date or return the one found above
							date ||= WhenDate.create!(:date => issue_date)
							#Create a document
							document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)

							#Create an occasion for the date in the project, country, document and standard
							project.occasions.build(:description => "Issue date", :country_id => country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)

							project.save!
							#Grab the Upload date
							if d.parent.parent.last_element_child.inner_text !~ /VCS/ then
								puts "#{d.parent.parent.last_element_child.inner_text} - #{doc_title} - #{process_type}"
								doc_upload_time = Date.parse(d.parent.parent.last_element_child.inner_text)
							else
								doc_upload_time = issue_date
							end
							#Check if date exists
							date = WhenDate.where('date = ?', doc_upload_time).first
							#Write in the new date or return the one found above
							date ||= WhenDate.create!(:date => doc_upload_time)
							#Create an occasion for the date in the project, country, document and standard
							project.occasions.build(:description => "Upload date", :country_id => country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
							project.save!
						end
					end
					
					if !vcs_page_html.search("td:nth-child(2) a").empty? then
						#Grab all registration documents
						vcs_page_html.search("td:nth-child(2) a").each do |d|
							#Find the document's URL
							doc_url = d.parent.last_element_child['href'].strip.prepend("https://vcsprojectdatabase2.apx.com")
							#Find the title of the document
							doc_title = d.parent.parent.first_element_child.text

							short_doc_title = ""
							
							#Write project url into the database
							if d.parent.parent.first_element_child.parent.parent.parent.first_element_child.text == "Issuance Documents"
								process_type = "Issuance"
							else
								process_type = "Unknown"
							end
							#Check if date exists
							date = WhenDate.where('date = ?', issue_date).first
							#Write in the new date or return the one found above
							date ||= WhenDate.create!(:date => issue_date)
							#Create a document
							document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)
							#Create an occasion for the date in the project, country, document and standard
							project.occasions.build(:description => "Issue date", :country_id => country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
							project.save!

							#Grab the Upload date
							if d.parent.parent.last_element_child.inner_text !~ /VCS/ then
								puts "#{d.parent.parent.last_element_child.inner_text} - #{doc_title} - #{process_type}"
								doc_upload_time = Date.parse(d.parent.parent.last_element_child.inner_text)
							else
								doc_upload_time = issue_date
							end
							#Check if date exists
							date = WhenDate.where('date = ?', doc_upload_time).first
							#Write in the new date or return the one found above
							date ||= WhenDate.create!(:date => doc_upload_time)
							#Create an occasion for the date in the project, country, document and standard
							project.occasions.build(:description => "Upload date", :country_id => country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
							#Save the database entries
							project.save!
						end
					end
					#Save the database entries
					project.save!

					vcs_page_html = vcs_page_html.text.encode!("utf-8", "utf-8", :invalid => :replace)
					crawl.update_attributes(:html => vcs_page_html, :project_id => project.id, :status_code => 2)
					crawl.touch
					crawl.save
					puts "#{vcs_proj_id}. #{vcs_proj_title} - #{vcs_host_country} - Project ID #{project.id}"
				else
					vcs_page_html = vcs_page_html.text.encode!("utf-8", "utf-8", :invalid => :replace)
					crawl.update_attributes(:html => vcs_page_html, :project_id => vcs_proj_id, :status_code => 5)
					crawl.touch
					crawl.save
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The page is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The page is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
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
			mark_page_url = crawl.url
			puts "Starting on #{crawl.url}"
			sleep 5
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
				if !title.empty? and !id.empty? and !Project.find_by_title(title) then
					#Find the full location of the project
					location = mark_page_html.css(".unitTable tr:nth-child(3) td").text
					if !location.index(',').nil? then
						#Extract the country name from location
						country_name = location.reverse[0..location.reverse.index(',')-1].reverse.strip
					else
						country_name = "Unknown"
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
					#Check if country name exists
					country = Country.where('name = ?', country_name).first
					#Write in the new country names or return the one found above
					country ||= Country.create(:name => country_name)
					#define countries role
					role = "Host"
					#Create a role for the country in the project
					project.roles.build(:country_id => country.id, :role => role)
					#Save the database entries
					project.save!
					#Write the standard name
					standard = Standard.create(:name => standard, :short_name => short_standard, :project_id => project.id)
					#Define the issue date of the document
					issue_date = "01.01.2000"
					#Grab the list of mark_page_htmluments and loop throu it recording the titles and links					
					mark_page_html.css(".doc").each do |d|
						doc_url = d['href'].strip.prepend("http://mer.markit.com")
						#Find the document id
						#doc_id = doc_url.reverse[0..14].reverse.prepend(" - ")
						#Find the title of the document
						doc_title = d.children.text
						short_doc_title = ""
						if doc_title =~ /project design document|project design description|pdd/i then
							short_doc_title = "PDD"
						end
						if doc_title =~ /monitoring report/i then
							short_doc_title = "MR"
						end
						if doc_title =~ /verification report/i then
							short_doc_title = "VerR"
						end
						if doc_title =~ /validation report/i then
							short_doc_title = "ValR"
						end
						#Ammend the title of the document with ID at the end (for control purposes)
						#doc_title = doc_id.prepend(d.children.text)
						process_type = "Unknown"
						if !(doc_title =~ /valid|pdd|design|idea|gsp|registration|determin|descrip|passp|stakehol| oda /i).nil? then
							process_type = "Registration"
						end
						if !(doc_title =~ /verif|monito|issuan/i).nil? then
							process_type = "Issuance"
						end

						#Check if date exists
						date = WhenDate.where('date = ?', issue_date).first
						#Write in the new date or return the one found above
						date ||= WhenDate.create!(:date => issue_date)
						#Create a document
						document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)
						#Create an occasion for the date in the project, country, document and standard
						project.occasions.build(:description => "Issue date", :country_id => country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
						project.save!

						#Grab the Upload date
						doc_upload_time = issue_date
						#Check if date exists
						date = WhenDate.where('date = ?', doc_upload_time).first
						#Write in the new date or return the one found above
						date ||= WhenDate.create!(:date => doc_upload_time)
						#Create an occasion for the date in the project, country, document and standard
						project.occasions.build(:description => "Upload date", :country_id => country.id, :when_date_id => date.id, :standard_id => standard.id, :document_id => document.id)
						#Save the database entries
						project.save!
					end
					
					mark_page_html = mark_page_html.text.encode!("utf-8", "utf-8", :invalid => :replace)
					crawl.update_attributes(:html => mark_page_html, :project_id => project.id, :status_code => 2)
					crawl.touch
					crawl.save
					puts "#{short_standard}#{proj_id} - #{title} - #{country.name}"
					project.documents.each do |d|
						puts "#{d.id} #{d.title}"
					end
				else
					mark_page_html = mark_page_html.text.encode!("utf-8", "utf-8", :invalid => :replace)
					if Project.find_by_title(title) then
						puts "Project is the same as in the VCS registry. We don't need duplication!"
						project_id = Project.find_by_title(title).id
						crawl.update_attributes(:html => mark_page_html, :project_id => project_id, :status_code => 5)
						crawl.touch
						crawl.save
					else
						puts "Empty project"
						crawl.update_attributes(:html => mark_page_html, :status_code => 5)
						crawl.touch
						crawl.save
					end
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The page is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
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

def new_cdm_doe_crawler(webcrawls = Webcrawl.where(:source => "cdm_doe", :status_code => 1))
 	puts "Collecting new CDM DOEs"
	webcrawls.each do |crawl|
		begin
			cdm_doe_page_url = crawl.url

			puts "#{cdm_doe_page_url}"

			status = Timeout::timeout(20) {
				page_html = open(cdm_doe_page_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
				doe_page = Nokogiri::HTML(page_html)
				doe_page_html = doe_page.css("html body div#container div#content div#cols div#main").children[7].children[1].children[1]
				#Retrive the DOE ID and the Name
				cdm_doe_id_name = doe_page_html.children[0].children[2].children[1].children[0].text

				puts "#{cdm_doe_id_name}"

				#Retrieve only the name
				cdm_doe_name = cdm_doe_id_name[cdm_doe_id_name.index(".")+2..-1]
				puts "#{cdm_doe_name}"
				
				#Find short and long names of DOE
				doe_name_finder(cdm_doe_name)				
				short_doe_name = @a[0]
				doe_name = @a[1]
				puts "#{doe_name}, #{short_doe_name}"

				#Find the validation and verification scopes of accreditation
				#cdm_doe_val_scope = doe_page_html.children[2].children[2].children[1].children[0].text
				#cdm_doe_ver_scope = doe_page_html.children[2].children[2].children[4].children[0].text

				#Find the city/county
				#cdm_doe_city = doe_page_html.children[3].children[2].children[3].children[0].text

				#Find the postal code
				#cdm_doe_postal = doe_page_html.children[3].children[2].children[13].children[0].text

				#Find the postal address
				#cdm_doe_address = doe_page_html.children[3].children[2].children[18].children[0].text

				#Find the contact details
				#cdm_doe_contact = doe_page_html.children[4].children[2].children.text.gsub(/\s{2,}/," ").strip

				#Retreave the country of DOE's location
				if !doe_page_html.children[3].children[2].children[8].nil?
					if doe_page_html.children[3].children[2].children[6].children[0].text == "Postal Address: "
						doe_country = "China"
					else
						doe_country = doe_page_html.children[3].children[2].children[8].children[0].text
					end
				else
					doe_country = "Republic of Korea"
				end

				# if doe_country == "United States" then
				# 	doe_country = "United States of America"
				# end
				puts "#{doe_country}"

				#Check if country name exists
				@country = Country.where('name like ?', doe_country).first
				#Write in the new country names or return the one found above
				@country ||= Country.create!(:name => doe_country)				
				
				#Check if stakeholder exists
				stakeholder = Stakeholder.where('title = ? and country_id = ?', doe_name, @country.id).first
				#Create a new DOE if it doesn't exist yet
				stakeholder ||= Stakeholder.create!(:title => doe_name, :short_title => short_doe_name, :country_id => @country.id)

				#Update the crawl record for the project page
				crawl.update_attributes(:html => doe_page_html.to_html, :status_code => 2)
				crawl.touch
				crawl.save
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The page is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
				crawl.touch
				crawl.save
			end
		end
		if !@timed_out.empty? then
			puts "There were some timeouts."
			#Selecting all pages with timeouts so far
			webcrawls = Webcrawl.find(@timed_out)
			#Empty the timeout for next time
			@timed_out = []
			#Calling the same method but only with the timed out pages
			new_cdm_doe_crawler(webcrawls)
			#No timeouts
		else
			puts "Moving on."
		end
	end
end

def new_vcs_doe_crawler(webcrawls = Webcrawl.where(:source => "vcs_doe", :status_code => 1))
 	puts "Collecting new VCS DOEs"
	webcrawls.each do |crawl|
		begin
			vcs_doe_page_url = crawl.url
			puts "#{vcs_doe_page_url}"
			status = Timeout::timeout(20) {
				@agent.get(vcs_doe_page_url)
				@agent.page.encoding = 'ISO-8859-1'
				@agent.page.encoding = 'cp1252'
				doe_page_html = @agent.page.search("html body div#content")
				
				#Find the ID number for VCS DOE
				#vcs_doe_id = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[1].children[3].children[0].text

				#Find the contact details
				#vcs_doe_contact = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[3].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				
				#Find VCS DOE' website address
				#vcs_doe_website = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[7].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				#Find VCS DOE's accreditation body
				#vcs_doe_accr = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[9].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				#Retrieve only the name
				vcs_doe_name = @agent.page.search(".title").children[0].text

				puts "#{vcs_doe_name}"

				#Find short and long names of DOE
				doe_name_finder(vcs_doe_name)				
				short_doe_name = @a[0]
				doe_name = @a[1]
				puts "#{doe_name}, #{short_doe_name}"

				#Find the validation and verification scopes of accreditation
				#vcs_doe_val_scope = @agent.page.search("div#block-views-vvb-accreditations-block .views-table tbody .views-field-field-sectoral-scope").text.gsub(/\s{2,}/," ").strip
				#vcs_doe_ver_scope = @agent.page.search("div#block-views-vvb-accreditations-block-1 .views-table tbody .views-field-field-sectoral-scope").text.gsub(/\s{2,}/," ").strip

				#Find DOE's location
				vcs_doe_location = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[5].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				puts "#{vcs_doe_location}"

				doe_country = "Unknown"

				#Retreave the country of DOE's location
				country_list = Country.all
				country_list.each do |c|
					if vcs_doe_location.include? c.name.to_s
						doe_country = c.name.to_s
						#puts "found it! #{c.name.to_s}"
					end
				end

				puts "#{doe_country}"

				#Check if country name exists
				@country = Country.where('name = ?', doe_country).first
				#Write in the new country names or return the one found above
				@country ||= Country.create!(:name => doe_country)				
				
				#Check if stakeholder exists
				stakeholder = Stakeholder.where('title = ?', doe_name).first
				#Create a new DOE if it doesn't exist yet
				stakeholder ||= Stakeholder.create!(:title => doe_name, :short_title => short_doe_name, :country_id => @country.id)

				#Update the crawl record for the project page
				crawl.update_attributes(:html => doe_page_html.to_html, :status_code => 2)
				crawl.touch
				crawl.save
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
		rescue OpenURI::HTTPError => ex
			if crawl.retries > 0
				puts "The page is missing or not responding"
				#Decrease the number of retries
				crawl.retries -= 1
				#Put the id of the project into the array for the rescan later
				@timed_out << crawl.id
				crawl.touch
				crawl.save
			else
				puts "The page at #{crawl.url} is gone"
				#Constant 404 is status 5
				crawl.status_code = 5
				crawl.touch
				crawl.save
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
end

def doe_name_finder(name)
	
	if name =~ /DNV|Det Norske Veritas Climate Change Services/ then
		short_doe_name = "DNV"
		doe_name = "Det Norske Veritas Climate Change Services AS"
	end
	if name =~ /TUEV-R|Rheinland \u0028China\u0029/ then
		short_doe_name = "T" + "\u00dc" + "VRHEIN"
		doe_name = "T" + "\u00dc" + "V Rheinland (China), Ltd."
	end
	if name =~ /Rheinland Energie|Rheinland Energie/ then
		short_doe_name = "T" + "\u00dc" + "VREU"
		doe_name = "T" + "\u00dc" + "V Rheinland Energie und Umwelt GmbH"
		doe_country = "Germany"
	end
	if name =~ /TUEV-SUED|South Asia Private|Industrie Service GmbH/ then
		short_doe_name = "T" + "\u00dc" + "V S" + "\u00dc" + "D"
		doe_name = "T" + "\u00dc" + "V S" + "\u00dc" + "D South Asia Private Ltd. (formerly T" + "\u00dc" + "V S" + "\u00dc" + "D Industrie Service GmbH)"
	end
	if name =~ /RWTUV|NORD CERT|T\u00dcV NORD|Nord Cert GmbH/ then
		short_doe_name = "T" + "\u00dc" + "VNORD"
		doe_name = "T" + "\u00dc" + "V NORD CERT GmbH"
	end
	if name =~ /SGS/ then
		short_doe_name = "SGS"
		doe_name = "SGS United Kingdom, Ltd."
	end
	if name =~ /AENOR|Spanish Association for Standardisation/ then
		short_doe_name = "AENOR"
		doe_name = "Spanish Association for Standardisation and Certification"
	end
	if name =~ /BVQI|Bureau Veritas/ then
		short_doe_name = "BVCH"
		doe_name = "Bureau Veritas Certification Holding SAS"
	end
	if name =~ /KEMCO|Korea Energy Management Corporation/ then
		short_doe_name = "KEMCO"
		doe_name = "Korea Energy Management Corporation"
	end
	if name =~ /JQA|Japan Quality Assurance Organisation/ then
		short_doe_name = "JQA"
		doe_name = "Japan Quality Assurance Organisation"
	end
	if name =~ /KPMG/ then
		short_doe_name = "KPMG"
		doe_name = "KPMG Performance Registrar, Inc."
	end
	if name =~ /JACO/ then
		short_doe_name = "JACO"
		doe_name = "JACO CDM, Ltd."
	end
	if name =~ /JCI|Japan Consulting Institute/ then
		short_doe_name = "JCI"
		doe_name = "Japan Consulting Institute"
	end
	if name =~ /LRQA|Register Quality Assurance/ then
		short_doe_name = "LRQA"
		doe_name = "Lloyd's Register Quality Assurance, Ltd."
	end
	if name =~ /ICONTEC|Colombian Institute for Technical Standards/ then
		short_doe_name = "ICONTEC"
		doe_name = "Colombian Institute for Technical Standards and Certification"
	end
	if name =~ /KFQ|Korean Foundation for Quality/ then
		short_doe_name = "KFQ"
		doe_name = "Korean Foundation for Quality"
	end
	if name =~ /SQS|Swiss Association for Quality/ then
		short_doe_name = "SQS"
		doe_name = "Swiss Association for Quality and Management Systems"
	end
	if name =~ /PJR|PJRCES|Perry Johnson/ then
		short_doe_name = "PJRCES"
		doe_name = "Perry Johnson Registrars Carbon Emissions Services"
	end
	if name =~ /KECO|Korea Environment Corporation/ then
		short_doe_name = "KECO"
		doe_name = "Korea Environment Corporation"
	end
	if name =~ /KBS/ then
		short_doe_name = "KBS"
		doe_name = "KBS Certification Services Pvt., Ltd."
	end
	if name =~ /HKQAA|Hong Kong Quality Assurance/ then
		short_doe_name = "HKQAA"
		doe_name = "Hong Kong Quality Assurance Agency"
	end
	if name =~ /URS/ then
		short_doe_name = "URS"
		doe_name = "URS Verification Private, Ltd."
	end
	if name =~ /KTR|Korea Testing|KTDCert/ then
		short_doe_name = "KTR"
		doe_name = "Korea Testing and Research Institute"
	end
	if name =~ /RINA/ then
		short_doe_name = "RINA"
		doe_name = "RINA Services S.p.A."
	end
	if name =~ /ERM Certification|ERM-CVS/ then
		short_doe_name = "ERM-CVS"
		doe_name = "ERM Certification and Verification Services, Ltd."
	end
	if name =~ /ReConsult|Re-consult|re-consult/ then
		short_doe_name = "RC"
		doe_name = "Re-consult, Ltd."
	end
	if name =~ /China Quality|CQC/ then
		short_doe_name = "CQC"
		doe_name = "China Quality Certification Center"
	end
	if name =~ /SIRIM/ then
		short_doe_name = "SIRIM"
		doe_name = "SIRIM Quality Assurance Services International Sdn. Bhd."
	end
	if name =~ /CEC|China Environmental United/ then
		short_doe_name = "CEC"
		doe_name = "China Environmental United Certification Center Co., Ltd. "
	end
	if name =~ /JMA|Japan Management Association/ then
		short_doe_name = "JMA"
		doe_name = "Japan Management Association"
	end
	if name =~ /TECO|Deloitte/ then
		short_doe_name = "DTECO"
		doe_name = "Deloitte Tohmatsu Evaluation and Certification Organization"
	end
	if name =~ /GLC|Germanischer/ then
		short_doe_name = "GLC"
		doe_name = "Germanischer Lloyd Certification GmbH"
	end
	if name =~ /Applus|LGAI|Applus+/ then
		short_doe_name = "LGAI"
		doe_name = "LGAI Technological Center, S.A."
	end
	if name =~ /ErnstYoung|Ernst & Young|EYG/ then
		short_doe_name = "EYG"
		doe_name = "Ernst & Young Associ" + "\u00e9" + "s"
	end
	if name =~ /CEPREI/ then
		short_doe_name = "CEPREI"
		doe_name = "CEPREI certification body"
	end
	if name =~ /CCSC|China Classification/ then
		short_doe_name = "CCSC"
		doe_name = "China Classification Society Certification Company"
	end
	if name =~ /Korean Standards|KSA/ then
		short_doe_name = "KSA"
		doe_name = "Korean Standards Association"
	end
	if name =~ /emc/ then
		short_doe_name = "EMC"
		doe_name = "Environmental Management Corporation"
		doe_country = "South Korea"
	end
	if name =~ /BSI/ then
		short_doe_name = "BSI"
		doe_name = "BSI Management Systems"
		doe_country = "United Kingdom of Great Britain and Northern Ireland"
	end
	if name =~ /CRA|Conestoga/ then
		short_doe_name = "CRA"
		doe_name = "Conestoga-Rovers and Associates, Ltd."
		doe_country = "Canada"
	end
	if name =~ /ICFRE|Indian Council/ then
		short_doe_name = "ICFRE"
		doe_name = "Indian Council of Forestry Research and Education"
	end
	if name =~ /Carbon Check|CarbonCheck/ then
		short_doe_name = "CC"
		doe_name = "Carbon Check (Pty), Ltd."
	end
	if name =~ /IBOPE/ then
		short_doe_name = "IBOPE"
		doe_name = "IBOPE Instituto Brasileiro de Opini"+"\u00e3"+"o P"+"\u00fa"+"blica e Estat"+"\u00ed"+"stica, Ltda."
	end
	if name =~ /MASCI|Foundation for Industrial/ then
		short_doe_name = "MASCI"
		doe_name = "Foundation for Industrial Development"
	end
	if name =~ /KR|Korean Register/ then
		short_doe_name = "KR"
		doe_name = "Korean Register of Shipping"
	end
	if name =~ /CTI/ then
		short_doe_name = "CTI"
		doe_name = "Shenzhen CTI International Certification Co., Ltd."
	end
	if name =~ /Ecocert/ then
		short_doe_name = "EC"
		doe_name = "Ecocert S.A."
		doe_country = "France"
	end
	if name =~ /Environmental Services, Inc./ then
		short_doe_name = "ES"
		doe_name = "Environmental Services, Inc."
	end
	if name =~ /First Environment/ then
		short_doe_name = "FE"
		doe_name = "First Environment, Inc."
	end
	if name =~ /NSF International/ then
		short_doe_name = "NSFISR"
		doe_name = "NSF International Strategic Registrations, Ltd."
	end
	if name =~ /Rainforest/ then
		short_doe_name = "RA"
		doe_name = "Rainforest Alliance, Inc."
	end
	if name =~ /Ruby/ then
		short_doe_name = "RCE"
		doe_name = "Ruby Canyon Engineering, Inc."
	end
	if name =~ /SCS Global/ then
		short_doe_name = "SCS"
		doe_name = "SCS Global Services"
	end
	if name =~ /Stantec/ then
		short_doe_name = "SC"
		doe_name = "Stantec Consulting"
	end
	# if name =~ // then
	# 	short_doe_name = ""
	# 	doe_name = ""
	# end
	
	@a = Array.new
	@a << short_doe_name
	@a << doe_name
end

def define_pp(country, project, role, hash = {})
	hash.each do |c|
		pp_name = c.to_s
		if c =~ /\u0028withdrawn\u0029|\u0028 withdrawn\u0029|\u0028 withdrawn \u0029|\u0028withdrawn\u0029/ then
			pp_name = c.gsub(" (withdrawn)", "").gsub("(withdrawn)", "").gsub("( withdrawn)", "").gsub("(withdrawn) ", "").gsub("(withdrawn )", "").gsub("( withdrawn )", "").strip
		end
		#Check if stakeholder exists
		stakeholder = Stakeholder.where('title = ?', pp_name).first
		#Create a new DOE if it doesn't exist yet
		stakeholder ||= Stakeholder.create!(:title => pp_name, :country_id => country.id)

		project.entities.build(:project_id => project.id, :stakeholder_id => stakeholder.id, :role => role)
		project.save!
		puts "Stakeholder #{stakeholder.title} was connected to the project #{project.id} as #{role}"
	end
end

new_cdm_doe_crawler
new_vcs_doe_crawler

#vcs_update_page_crawler
#vcs_new_page_crawler
#markit_update_page_crawler
#markit_new_page_crawler
cdm_new_page_crawler
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