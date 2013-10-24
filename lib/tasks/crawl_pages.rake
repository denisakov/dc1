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
	@default_date = "01.01.2000"

def cdm_gsp_page_updater(webcrawls = Webcrawl.where(:source => "cdm_gsp", :status_code => 2))
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

def cdm_gsp_page_crawler(webcrawls = Webcrawl.where(:source => "cdm_gsp", :status_code => 1))
 	puts "Collecting new CDM projects"
 	
	webcrawls.each do |crawl|
		t=20
		begin
			
			@entity_list = Array.new
			@date_list = Array.new
			gsp_page_url = crawl.url

			status = Timeout::timeout(t) {
				puts ""
				puts ""
				puts "Started on #{gsp_page_url}"
				page_html = open(gsp_page_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
				gsp_page = Nokogiri::HTML(page_html)
				gsp_page_html = gsp_page.css("html body div#container div#content div#cols div#main")
				#Retrive the project ID and the Title
				cdm_proj_id_title = gsp_page_html.css("div.mH div").text.strip.gsub( "\u0096", "-" )
				#Retrieve the project ID
				cdm_proj_id = cdm_proj_id_title[12..18].strip
				#Retreave the project title
				cdm_proj_title = cdm_proj_id_title[cdm_proj_id_title.index(":")+1..cdm_proj_id_title.length].strip

				#Find if there is a funds section
				if gsp_page_html.css("tr:nth-child(4) th").inner_text.strip == "Bilateral and Multilateral Funds"
					#Grab the sectoral scope
					cdm_scope = gsp_page_html.css("tr:nth-child(5) td").text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip
					#Grab the project scale
					cdm_proj_scale = gsp_page_html.css("tr:nth-child(6) td").children[0].text.strip.capitalize!
					#Grab the methodologies used
					cdm_meths = gsp_page_html.css("tr:nth-child(7) span").text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip
					#Grab the amount of emission reductions
					cdm_er = gsp_page_html.css("tr:nth-child(8) td").text.gsub(/\n/,"").gsub(/\s{2,}/," ").gsub(/[^\d]/,"")[0..-2]
					#Retreave the fee amount
					cdm_fee = gsp_page_html.css("tr:nth-child(9) td").text.gsub(/\n/,"").gsub(/\s{2,}/," ")[5..-2]
					#Find the registration date
					if gsp_page_html.css("tr:nth-child(11) td").children[1].text  =~ /[\d]/
						cdm_reg_date = parse_date(gsp_page_html.css("tr:nth-child(11) td").children[1])
						@date_list << [cdm_reg_date.id, "Project registered by CDM EB", nil]
					else
						cdm_reqr_date = "Review Requested"
						cdm_wdr_date = "Withdrawn"
						cdm_rj_date = "Rejected"
					end
					if gsp_page_html.css("tr:nth-child(12)").text =~ /Crediting/
						#find creditting period starting date
						parse_period(gsp_page_html.css("tr:nth-child(12) td").children[0])
						cdm_sp1_st_date = @start_date
						@date_list << [cdm_sp1_st_date.id, "1st crediting period started", nil]
						#find creditting period end date
						cdm_sp1_fn_date = @end_date
						@date_list << [cdm_sp1_fn_date.id, "1st crediting period ended", nil]
						if  gsp_page_html.css("tr:nth-child(12) td").children[3] =~ /Subsequent/ then
							parse_period(gsp_page_html.css("tr:nth-child(12) td").children[5])
							cdm_sp2_st_date = @start_date
							@date_list << [cdm_sp2_st_date.id, "2nd crediting period started", nil]
							cdm_sp2_fn_date = @end_date
							@date_list << [cdm_sp2_fn_date.id, "2nd crediting period ended", nil]
						end
						if gsp_page_html.css("tr:nth-child(12) td").children[2] =~ /Changed/ then
							parse_period(gsp_page_html.css("tr:nth-child(12) td").children[3])
							cdm_sp1_old_st_date = @start_date
							@date_list << [cdm_sp1_old_st_date.id, "1st crediting period should have started (changed)", nil]
							cdm_sp1_old_fn_date = @end_date
							@date_list << [cdm_sp1_old_fn_date.id, "1st crediting period should have ended (changed)", nil]
						end
					end

				else
					cdm_scope = gsp_page_html.css("tr:nth-child(4) td").text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip
					
					cdm_proj_scale = gsp_page_html.css("tr:nth-child(5) td").children[0].text.strip.capitalize!
					cdm_meths = gsp_page_html.css("tr:nth-child(6) span").text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip
					cdm_er = gsp_page_html.css("tr:nth-child(7) td").text.gsub(/\n/,"").gsub(/\s{2,}/," ").gsub(/[^\d]/,"")[0..-2]
					cdm_fee = gsp_page_html.css("tr:nth-child(8) td").text.gsub(/\n/,"").gsub(/\s{2,}/," ")[5..-2]
					if gsp_page_html.css("tr:nth-child(10) td").children[1].text =~ /[\d]/
						cdm_reg_date = parse_date(gsp_page_html.css("tr:nth-child(10) td").children[1])
						@date_list << [cdm_reg_date.id, "Project registered by CDM EB", nil]
					else
						cdm_reqr_date = "Review Requested"
						cdm_wdr_date = "Withdrawn"
						cdm_rj_date = "Rejected"
					end
					if gsp_page_html.css("tr:nth-child(11)").text =~ /Crediting/
						parse_period(gsp_page_html.css("tr:nth-child(11) td").children[0])
						cdm_sp1_st_date = @start_date
						@date_list << [cdm_sp1_st_date.id, "1st crediting period started", nil]
						cdm_sp1_fn_date = @end_date
						@date_list << [cdm_sp1_fn_date.id, "1st crediting period ended", nil]
						if  gsp_page_html.css("tr:nth-child(11) td").children[3] =~ /Subsequent/ then
							parse_period(gsp_page_html.css("tr:nth-child(11) td").children[5])
							cdm_sp2_st_date = @start_date
							@date_list << [cdm_sp2_st_date.id, "2nd crediting period started", nil]
							cdm_sp2_fn_date = @end_date
							@date_list << [cdm_sp2_fn_date.id, "2nd crediting period ended", nil]
						end
						if gsp_page_html.css("tr:nth-child(11) td").children[2] =~ /Changed/ then
							parse_period(gsp_page_html.css("tr:nth-child(11) td").children[3])
							cdm_sp1_old_st_date = @start_date
							@date_list << [cdm_sp1_old_st_date.id, "1st crediting period should have started (changed)", nil]
							cdm_sp1_old_fn_date = @end_date
							@date_list << [cdm_sp1_old_fn_date.id, "1st crediting period should have ended (changed)", nil]
						end
					end
				end
				puts "#{cdm_scope}, #{cdm_meths}, #{cdm_er}"
				if cdm_reg_date then
					puts "Registration date #{cdm_reg_date.date.strftime("%F")}"
				else
					puts "Project wasn't registered"
				end

				puts "#{cdm_sp1_st_date}"
				puts "#{cdm_sp1_fn_date}"
				
				#Create a new project record
				project = Project.create!(:title => cdm_proj_title, :refno => cdm_proj_id, :scale => cdm_proj_scale, :fee => cdm_fee)
				@project = project
				std_name = "Clean Development Mechanism"
				srt_name = "CDM"
				#Write the standard name
				@standard = check_standard(std_name, srt_name)

				check_scheme("", project, @standard)
				
				puts "#{project.id}, CDM#{cdm_proj_id}, #{cdm_proj_title}, #{cdm_proj_scale}, $#{cdm_fee}"
				
				#Analyse the block of "Host country"
				gsp_page_html.css("tr:nth-child(2)").children[2].children.each do |a|
					if !a.text.strip.empty? then
						#Retreave the country name
						cdm_host_country = a.children[1].text
						puts "Host country is #{cdm_host_country}"
						#Grab the first link from "approval"; ignoring the "authorization" for now, because they are mostly the same
						doc_url = a.children[5]['href']
						#set the role variable
						country_role = "Host"
						#set the process variable
						process_type = "Registration"
						#set the doc title; including the country name into doc's name for now.
						doc_title = "Letter of Approval"
						#set document short name
						short_doc_title = "LoA"
						
						#Create a document
						document = Document.create!(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)
						
						#Define the issue date of the document
						issue_date = parse_date(@default_date)
						@date_list << [issue_date.id, "Issue date", document.id]

						@host_country = check_country(cdm_host_country)
						
						#Create a role for the country in the project
						project.roles.build(:country_id => @host_country.id, :role => country_role)						
						project.save!
						
						#Grab all the project participants
						#-----------------------------------
						if a.children[3].text =~ /involved/ then
							host_pps = a.children[12].text.gsub(/Authorized Participants:/, '').strip.split(%r{;\s*})
						else
							host_pps = a.children[10].text.gsub(/Authorized Participants:/, '').strip.split(%r{;\s*})
						end
						#-----------------------------------

						sth_role = "host_pp"
						define_pp(@host_country, project, sth_role, host_pps)
						
						#Find registering DOE
						short_doe_name = gsp_page_url.gsub("http://cdm.unfccc.int/Projects/DB/", "").gsub("/view?cp=", "").gsub(/[\d]/,"").gsub("%", " ").gsub(".","")
						doe_name_finder(short_doe_name)
						short_doe_name = @a[0]
						doe_name = @a[1]
						if @a[2] then
							doe_country = Country.where('name = ?', @a[2]).first
						else
							doe_country = Country.where('name = ?', "Unknown").first
						end
						
						@val_doe = check_doe(doe_name, short_doe_name, doe_country.id)
						
						#Define the role of the entity in the project
						ent_role = "val_doe"

						project.stakeholders.build(:project_id => project.id, :entity_id => @val_doe.id, :role => ent_role)
						puts "#{@val_doe.id} #{doe_name} - Validating DOE"
						
						project.save!
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
							new_pdd_acc_date = parse_date(a.next.next.inner_text)
							#Create a document
							document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)
							
							@date_list << [newe_pdd_acc_date.id, "PDD was accepted by CDM EB", document.id]
							
						end
						#Define the issue date of the document
						issue_date = parse_date(@default_date)
						#Create a document
						document = Document.create(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)
						#Create an occasion for the date in the project, country, document and standard
						@date_list << [issue_date.id, "Issue date", document.id]
						
						puts "#{doc_title} | #{doc_url}"
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
							# if a.text.strip =~ /involved/ then
							# 	if a.text.strip =~ /indirectly/
							# 		inv_country_role = "indirectly"
							# 	else
							# 		inv_country_role = "directly"
							# 	end
							# end
							# inv_country_role ||= "Unknown"
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
							

							inv_country = check_country(cdm_inv_country)

							#Create a role for the country in the project
							project.roles.build(:country_id => inv_country.id, :role => country_role)
							project.save!
							#======================================
							#Idenfify the project participants
							if a.children[10] then
								#Grab all the project participants
								inv_pps = a.children[10].text.gsub(/Authorized Participants:/, '').strip.split(%r{;\s*})
							else
								inv_pps = a.children[8].text.gsub(/Authorized Participants:/, '').strip.split(%r{;\s*})
							end
							#======================================

							pp_role = "a1_pp"
							define_pp(inv_country, project, pp_role, inv_pps)
							
							#Define the issue date of the document
							issue_date = parse_date(@default_date)
							#Create a document
							document = Document.create!(:title => doc_title, :short_title => short_doc_title, :process_type => process_type, :link => doc_url, :project_id => project.id)

							@date_list << [issue_date.id, "Issue date", document.id]

							#Create an occasion for the Document
							# project.occasions.build(:description => "Issue date", :country_id => inv_country.id, :when_date_id => issue_date.id, :standard_id => standard.id, :document_id => document.id)

							project.save!
							puts "Investor country is #{inv_country.name}"
						end
					end
				end

				# gsp_page_html.css("tr:nth-child(1)").children[2].children.each do |a|
				# end

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
			create_occasions(@project, @standard, @entity_list, @date_list)
			@project.save!

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
		rescue Timeout::Error => te		
			puts "The page seems to take longer than 20 seconds. Let's give it a bit more time."
			t+=300
			crawl.status_code = 1
			retry			
		end
	end

	if !@timed_out.empty? then
		puts "There were some timeouts."
		#Selecting all pages with timeouts so far
		webcrawls = Webcrawl.find(@timed_out)
		@timed_out = {}
		#Calling the same method but only with the timed out pages
		cdm_gsp_page_crawler(webcrawls)
	#No timeouts
	else
		puts "Moving on."
	end
end

# def cdm_cp2_page_updater(webcrawls = Webcrawl.where(:source => "cdm_cp2", :status_code => 2))
#  	puts "Updating info on CDM projects in their 2nd crediting period"
# 	webcrawls.each do |crawl|
# 		begin
# 			page_url = crawl.url

# 			status = Timeout::timeout(20) {
# 				}
# 		end
# 	end
# end

# def cdm_cp2_page_crawler(webcrawls = Webcrawl.where(:source => "cdm_cp2", :status_code => 1))
#  	puts "Collecting new info on CDM projects in their 2nd crediting period"
# 	webcrawls.each do |crawl|
# 		begin
# 			cp2_page_url = crawl.url

# 			status = Timeout::timeout(20) {
# 				puts "Started on #{cp2_page_url}"
# 				page_html = open(cp2_page_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
# 				cp2_page = Nokogiri::HTML(page_html)
# 				cp2_page_html = cp2_page.css("html body div#container div#content div#cols div#main")
				
# 				if cp2_page_html.to_html == gsp_page_html.to_html then
# 					puts "The Project did not reach the 2nd crediting period yet."
# 				else

# 				end

# 				#Update the crawl record for the project page
# 				crawl.update_attributes(:html => cp2_page_html.to_html, :status_code => 2)
# 				crawl.touch
# 				crawl.save
# 				}
# 		end
# 	end
# end

# def cdm_cp3_page_updater(webcrawls = Webcrawl.where(:source => "cdm_cp3", :status_code => 2))
#  	puts "Updating info on CDM projects in their 3rd crediting period"
# 	webcrawls.each do |crawl|
# 		begin
# 			page_url = crawl.url

# 			status = Timeout::timeout(20) {
# 				}
# 		end
# 	end
# end

# def cdm_cp3_page_crawler(webcrawls = Webcrawl.where(:source => "cdm_cp3", :status_code => 1))
#  	puts "Collecting new info on CDM projects in their 3rd crediting period"
# 	webcrawls.each do |crawl|
# 		begin
# 			cp3_page_url = crawl.url

# 			status = Timeout::timeout(20) {

				# puts "Started on #{cp3_page_url}"
				# page_html = open(cp3_page_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
				# cp3_page = Nokogiri::HTML(page_html)
				# cp3_page_html = cp3_page.css("html body div#container div#content div#cols div#main")
				
				# if cp2_page_html.to_html == cp3_page_html.to_html then
				# 	puts "The Project did not reach the 3rd crediting period yet."
				# end

				# #Update the crawl record for the project page
				# crawl.update_attributes(:html => cp3_page_html.to_html, :status_code => 2)
				# crawl.touch
				# crawl.save
# 				}
# 		end
# 	end
# end

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
					srt_name = "VCS"
					#Write the standard name
					@standard = check_standard(std_name, srt_name)

					check_scheme("", project, @standard)
					
					issue_date = @default_date
					
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
					std_name = mark_page_html.css(".unitTable tr:nth-child(2) td:nth-child(2)").text.strip
					#Identify which standard it is to see which short name to use
					srt_name = standard
					if std_name == "Gold Standard"
						srt_name = "GS"
					end
					if std_name == "Social Carbon"
						srt_name = "SC"
					end
					if std_name == "Verified Carbon Standard"
						srt_name = "VCS"
					end
					#Find the project reference number
					proj_id = id.text.delete "(ID: )"
						#puts proj_id


					#CHECK IF THE PROJECT EXISTS #################################################
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
					
					@standard = check_standard(std_name, srt_name)

					check_scheme("", project, @standard)

					#Define the issue date of the document
					issue_date = @default_date
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
			
			@entity_list = Array.new
			@date_list = Array.new

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

				#Check if country name exists
				doe_country = check_country(doe_page_html.children[3].children[2].text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip)

				puts "#{doe_country.name}"

				#Check if stakeholder exists and create it
				stakeholder = check_doe(doe_name, short_doe_name, doe_country.id)

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
				doe_page_html = @agent.page.search("html body div#main")
				
				#Find the ID number for VCS DOE
				#vcs_doe_id = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[1].children[3].children[0].text

				#Find the contact details
				#vcs_doe_contact = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[3].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				
				#Find VCS DOE' website address
				#vcs_doe_website = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[7].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				#Find VCS DOE's accreditation body
				#vcs_doe_accr = @agent.page.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[9].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				#Retrieve only the name
				vcs_doe_name = doe_page_html.search(".title").children[0].text

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
				vcs_doe_location = doe_page_html.search(".region .region-content").children[3].children[1].children[1].children[1].children[1].children[1].children[5].children[3].children[0].text.gsub(/\s{2,}/," ").strip

				puts "#{vcs_doe_location}"

				doe_country = check_country(vcs_doe_location)

				puts "#{doe_country.name}"
	
				#Check if entity exists
				stakeholder = check_doe(doe_name, short_doe_name, doe_country.id)
				
				puts "New company added #{stakeholder.title}"

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
	if name =~ /Performance Registrar/ then
		short_doe_name = "KPMGPR"
		doe_name = "KPMG Performance Registrar, Inc."
		doe_country = "Canada"
	end
	if name =~ /KPMG AZSA/ then
		short_doe_name = "KPMGAZSA"
		doe_name = "KPMG AZSA Sustainability Co., Ltd."
		doe_country = "Japan"
	end
	if name =~ /KPMG Advisory/ then
		short_doe_name = "KPMGA"
		doe_name = "KPMG Advisory N.V."
		doe_country = "Netherlands"
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
		short_doe_name = "URSVP"
		doe_name = "URS Verification Private, Ltd."
		doe_country = "India"
	end
	if name =~ /Verification Limited/ then
		short_doe_name = "URSV"
		doe_name = "URS Verification Limited"
		doe_country = "United Kingdom of Great Britain and Northern Ireland"
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
	if name =~ /BSI|British Standards Institution/ then
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
	if name =~ /Shenzhen CTI|CTI/ then
		short_doe_name = "CTI"
		doe_name = "Shenzhen CTI International Certification Co., Ltd."
		doe_country = "China"
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
	if name =~ /PricewaterhouseCoopers/ then
		short_doe_name = "PWC"
		doe_name = "Price Waterhouse Coopers"
		country = "South Africa"
	end
	if name =~ /Aarata|PWCASC/ then
		short_doe_name = "PWCASC"
		doe_name = "Pricewaterhouse Coopers Aarata Sustainability Certification Co. Ltd."
		country = "Republic of Korea"
	end
	if name =~ /Certification B.V|PWCC/ then
		short_doe_name = "PWCC"
		doe_name = "PricewaterhouseCoopers Certification B.V"
		country = "Netherlands"
	end
	if name =~ /Technology Institute of Parana|TECPAR/ then
		short_doe_name = "TECPAR"
		doe_name = "Technology Institute of Parana"
		country = "Republic of Korea"
	end
	if name =~ /Nippon Kaiji|NKKQAL/ then
		short_doe_name = "NKKQAL"
		doe_name = "Nippon Kaiji Kentei Quality Assurance Limited"
		country = "Japan"
	end	
	if name =~ /KICTEP|Transportation Technology Evaluation/ then
		short_doe_name = "KICTEP"
		doe_name = "Korea Institute of Construction & Transportation Technology Evaluation and Planning"
		country = "Republic of Korea"
	end
	if name =~ /Clouston/ then
		short_doe_name = "CE"
		doe_name = "Clouston Environmental Sdn. Bhd."
		country = "Malaysia"
	end
	if name =~ /Nexant/ then
		short_doe_name = "NEXANT"
		doe_name = "Nexant, Inc."
		country = "United States of America"
	end
	if name =~ /ECA CERT|ECA/ then
		short_doe_name = "ECACERT"
		doe_name = "ECA CERT, Certification, S.A."
		country = "Spain"
	end
	if name =~ /Tsinghua/ then
		short_doe_name = "TSINGHUA"
		doe_name = "Tsinghua"
		country = "China"
	end
	if name =~ /ADVANCED WASTE/ then
		short_doe_name = "AWMS"
		doe_name = "Advanced Waste Management Systems Inc."
		country = "Romania"
	end
	if name =~ /Dahua Engineering/ then
		short_doe_name = "DEMG"
		doe_name = "Dahua Engineering Management Group Ltd."
		country = "China"
	end
	if name =~ /INSPECCO/ then
		short_doe_name = "ICIS"
		doe_name = "Inspecco Certification and Inspection Services Ltd."
		country = "Turkey"
	end
	if name =~ /EPIC Sustainability/ then
		short_doe_name = "EPIC"
		doe_name = "EPIC Sustainability Services Pvt. Ltd."
		country = "India"
	end
	if name =~ /Northeast Audit/ then
		short_doe_name = "NAC"
		doe_name = "Northeast Audit Co., Ltd."
		country = "China"
	end
	# if name =~ // then
	# 	short_doe_name = ""
	# 	doe_name = ""
	# 	country = ""
	# end
	# if name =~ // then
	# 	short_doe_name = ""
	# 	doe_name = ""
	# 	country = ""
	# end
	@a = Array.new
	@a << short_doe_name
	@a << doe_name
	@a << doe_country
end

def define_pp(country, project, role, hash = {})
	hash.each do |c|
		pp_name = c.to_s
		if c =~ /\u0028withdrawn\u0029|\u0028 withdrawn\u0029|\u0028 withdrawn \u0029|\u0028withdrawn\u0029/ then
			pp_name = c.gsub(" (withdrawn)", "").gsub("(withdrawn)", "").gsub("( withdrawn)", "").gsub("(withdrawn) ", "").gsub("(withdrawn )", "").gsub("( withdrawn )", "").strip
		end
		#Check if entity exists
		entity = Entity.where('title = ?', pp_name).first
		#Create a new DOE if it doesn't exist yet
		entity ||= Entity.create!(:title => pp_name, :country_id => country.id)

		project.stakeholders.build(:project_id => project.id, :entity_id => entity.id, :role => role)
		project.save!
		puts "entity #{entity.title} was connected to the project #{project.id} as #{role}"

		if !@entity_list.include? entity.id
			@entity_list << entity.id
		end
		entity.save!
	end
end

def cdm_withdrawn_crawler
	begin	
		puts "Collecting withdrawn CDM projects"
		@date_list = Array.new
		@entity_list = Array.new
		
		status = Timeout::timeout(20) {
		wdr_page_url = "http://cdm.unfccc.int/Projects/withdrawn.html"
		page_html = open(wdr_page_url,'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2').read
		wdr_page = Nokogiri::HTML(page_html)
		wdr_page_html = wdr_page.css("html body div#container div#content div#cols div#main")

		wdr_page_html.children[7].search("tr")[1..-1].each do |p|
			wdr_proj_refno =  p.children[0].children[0].text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip
			project = Project.where(:refno => wdr_proj_refno).first
			if !project.blank? then
				proj_acc_date = Date.parse(p.children[8].children[0].text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip).strftime("%F")
				proj_wdr_date = Date.parse(p.children[10].children[0].text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip).strftime("%F")

				# host = p.children[4].children[1].children[1].children[0].text.gsub(/\n/,"").gsub(/\s{2,}/," ").strip

				acc_date = parse_date(proj_acc_date)
				@date_list << [acc_date.id, "Project submitted to CDM EB", nil]

				wdr_date = parse_date(proj_wdr_date)
				@date_list << [wdr_date.id, "Project withdrawn from CDM EB", nil]

				standard = project.standards.where(:short_name => "CDM").first
				
				project.entities.each do |s|
					if !@entity_list.include? s.id
						@entity_list << s.id
					end
				end
				

				create_occasions(project, standard, @entity_list, @date_list)
								
				#Update the crawl record for the project page
				crawl = Webcrawl.where(:url => wdr_page_url, :html => wdr_page_html.to_html, :source => "wdr", :status_code => 1).first
				crawl ||= Webcrawl.create!(:url => wdr_page_url, :html => wdr_page_html.to_html, :source => "wdr", :status_code => 1)
				crawl.save!
			end
		end
		}
	rescue Timeout::Error
		puts "Not enough time! Trying again"
		retry
	end		
end

def check_country(country)
	@found_country = nil
	IO.foreach('lib/assets/all_countries.txt') do |line|
		a = line.split(/\t/)[0].to_s
		if country.include? a or country.upcase.include? a.upcase then
			@found_country = a
			puts "Found #{@found_country} in general list"
		end
	end
	if !@found_country.nil? then
		final_country = Country.where('name = ?', @found_country).first
		final_country ||= Country.create!(:name => @found_country)

	else
		IO.foreach('lib/assets/country_replace.txt') do |line|
			line.split(/\t/)[1..-1].each do |a|
				if country.include? a.to_s
					@found_country = line.split(/\t/)[0].to_s
				end
			end
		end
	end
	if !@found_country.nil? then
		final_country = Country.where('name = ?', @found_country).first
		final_country ||= Country.create!(:name => @found_country)
	else
		country = "Unknown"
		final_country = Country.where('name = ?', country).first
		final_country ||= Country.create!(:name => country)
	end	

	final_country
end

def create_occasions(project, standard, entity_hash = {}, date_hash = {})
	
		entity_hash.each do |s|
			date_hash.each do |d|
				occasion = Occasion.where(:description => d[1], :project_id => project.id, :when_date_id => d[0], :standard_id => standard.id, :document_id => d[2], :entity_id => s).first
				if !occasion.nil? then
					puts "Found the occasion #{occasion.description}"
				else
					#Create an occasion for the Document
					project.occasions.build(:description => d[1], :project_id => project.id, :when_date_id => d[0], :standard_id => standard.id, :document_id => d[2], :entity_id => s)
					project.save!
					occasion = Occasion.where(:description => d[1], :project_id => project.id, :when_date_id => d[0], :standard_id => standard.id, :document_id => d[2], :entity_id => s).first
					puts "- #{occasion.description} - for project #{occasion.project_id} for company #{occasion.entity_id} on #{WhenDate.where('id = ?', d[0]).first.date}"
				end
			end
		end
end

def check_standard(std_name, srt_name)
	#Check if standard exists
	found_standard = Standard.where('name = ?', std_name).first
	#Write in the new standard or return the one found above
	found_standard ||= Standard.create!(:name => std_name, :short_name => srt_name)
end

def check_scheme(desc, project, standard)
	#Check if scheme exists
	found_scheme = Scheme.where('project_id = ? and standard_id = ?', project.id, standard.id).first
	if !found_scheme.nil? then
		puts "The project #{project_id} was listed under this #{standard.short_name} already"
	else
		#Write in the new scheme or return the one found above
		standard.schemes.build(:desc => desc, :project_id => project.id, :standard_id => standard.id)
		standard.save!
	end
end

def check_date(date)
	#Check if date exists
	found_date = WhenDate.where('date = ?', date).first
	#Write in the new date or return the one found above
	found_date ||= WhenDate.create!(:date => DateTime.parse(date.to_s,:utc).change(:offset => "+0200"))
end

def parse_period(period)
	period = period.text
	if period.index("(") then
		period = period.gsub(period[period.index("(")..period.index(")")], "")
	end
	start_date = DateTime.parse(period[period.index(/[\d]/)..period.index(" -")].gsub(/\n/,"").gsub(/\s{2,}/," ").strip, :utc).change(:offset => "+0200")
	end_date = DateTime.parse(period[period.index("- ")..-1].gsub(/\n/,"").gsub(/\s{2,}/," ").strip, :utc).change(:offset => "+0200")

	@start_date = check_date(start_date)
	@end_date = check_date(end_date)
end

def parse_date(date)
	if date.class != String
		date = date.text
	end
	if date.index("(") then
		date = date.gsub(date[date.index("(")..date.index(")")], "").stripd.date
	end
	one_date = DateTime.parse(date.strip, :utc).change(:offset => "+0200")

	@one_date = check_date(one_date)
end

def check_doe(name, short_name, country_id)
	#Identify the entity
	entity = Entity.where('title = ? and short_title = ?', name, short_name).first
	entity ||= Entity.create!(:title => name, :short_title => short_name, :country_id => country_id)
	if !@entity_list.include? entity.id
		@entity_list << entity.id
	end
	entity
end

new_cdm_doe_crawler
new_vcs_doe_crawler

#vcs_update_page_crawler
#vcs_new_page_crawler
#markit_update_page_crawler
#markit_new_page_crawler
cdm_gsp_page_crawler
# cdm_gsp_page_updater
# cdm_cp2_page_crawler
# cdm_cp2_page_updater
# cdm_cp3_page_crawler
# cdm_cp3_page_updater
cdm_withdrawn_crawler


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