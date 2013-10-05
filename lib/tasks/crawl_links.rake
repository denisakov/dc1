namespace :crawl do
	desc "collects and updates data from external sources"
	task :links => :environment do
		require 'rubygems'
		require 'open-uri'
		require 'nokogiri'
		require 'mechanize'
		require 'timeout'


		@timed_out = Array.new
		@array_to_scan = Array.new
		@missing = Array.new
		@agent = Mechanize.new
		@agent.idle_timeout = 0.9
		@r = 5
	
	def cdm_doe_link_finder
		try = 1
		begin
			puts "Looking for new DOEs under CDM"
			cdm_timeout = Timeout::timeout(20){
				@agent.get("http://cdm.unfccc.int/DOE/list/index.html")
			}
			@agent.page.links[36..-1].each do |l|
				cdm_doe_link = "http://cdm.unfccc.int/DOE/list/" + l.uri.to_s
				if Webcrawl.where('url = ?', cdm_doe_link).first.blank? then
					puts "That's a new one."
					crawl = Webcrawl.create!(:url => cdm_doe_link, :source => "cdm_doe", :status_code => 1, :retries => @r)
					puts cdm_doe_link
				else
					crawl = Webcrawl.where('url = ?', cdm_doe_link).first
					crawl.status_code = 2
					crawl.touch
					crawl.save
					puts "I've heard that one before."
					puts cdm_doe_link
				end
			end
		rescue Timeout::Error
			if try > 0
				puts "UNFCCC website doesn't respond, let's try again"
				try -= 1
				retry
			else
				sleep 10
				retry
			end
		rescue SocketError => e
			puts e.message
			puts "Most probably the internet connection is gone!"
		end
	end
	def vcs_doe_link_finder
		try = 1
		begin
			puts "Looking for new DOEs under VCSA"
			cdm_timeout = Timeout::timeout(20){
				@agent.get("http://www.v-c-s.org/verification-validation/find-vvb")
			}
			@agent.page.at("tbody").children.each do |l|
				vcs_doe_link = "http://www.v-c-s.org" + l.children[0].children[1].attributes["href"].to_s
				if Webcrawl.where('url = ?', vcs_doe_link).first.blank? then
					puts "That's a new one."
					crawl = Webcrawl.create!(:url => vcs_doe_link, :source => "vcs_doe", :status_code => 1, :retries => @r)
					puts vcs_doe_link
				else
					crawl = Webcrawl.where('url = ?', vcs_doe_link).first
					crawl.status_code = 2
					crawl.touch
					crawl.save
					puts "I've heard that one before."
					puts vcs_doe_link
				end
			end

		rescue Timeout::Error
			if try > 0
				puts "VCS website doesn't respond, let's try again"
				try -= 1
				retry
			else
				sleep 10
				retry
			end
		rescue SocketError => e
			puts e.message
			puts "Most probably the internet connection is gone!"
		end
	end
	def cdm_page_finder
		try = 1
		begin
			puts "Checking for new links on UNFCCC website!"
			cdm_timeout = Timeout::timeout(20){
				@agent.get("http://cdm.unfccc.int/Projects/projsearch.html")
			}
			#Choose the second form on the page
			form = @agent.page.forms[1]
			#Click "submit" button to see pages with all projects
			form.submit
			puts "Submitted the form"
		  	#Define maximum number of pages, by scanning the page numbers
			max = @agent.page.links[63].text.to_i
			if !Webcrawl.where(:source => ["cdm_gsp","cdm_cp2","cdm_cp3"]).order("last_page DESC").first.nil?
				lst = Webcrawl.where(:source => ["cdm_gsp","cdm_cp2","cdm_cp3"]).order("last_page DESC").first.last_page.to_i
				@array_to_scan = (lst..max).to_a
				puts "Scan will start from page #{lst} and end at page #{max}"
			else
				@array_to_scan = (0..max).to_a
				puts "Scan will start from scratch"
			end
		rescue Timeout::Error
			if try > 0
				puts "UNFCCC website doesn't respond, let's try again"
				try -= 1
				retry
			else
				sleep 10
				retry
			end
		rescue SocketError => e
			puts e.message
			puts "Most probably the internet connection is gone!"
		end
	end
	def cdm_link_collector(array_to_scan = @array_to_scan)
		array_to_scan.each do |i|
			try = 1
			begin
				puts "Scanning new page"
				cdm_timeout = Timeout::timeout(20){
					@agent.post('http://cdm.unfccc.int/Projects/projsearch.html', "page" => i)
				}
				page = @agent.page.parser()
			    #Grab all project links on the page and visit each one individually
				page.css("#projectsTable td:nth-child(2) a").each do |p|
			        #Define individual link
					gsp_page_url = p['href'].gsub(" ", "%20") + "?cp=1"
					if Webcrawl.where('url = ?', gsp_page_url).first.blank? then
						puts "That's a new one."
						crawl = Webcrawl.create!(:url => gsp_page_url, :source => "cdm_gsp", :last_page => i, :status_code => 1, :retries => @r)
						puts gsp_page_url
					else
						crawl = Webcrawl.where('url = ?', gsp_page_url).first
						crawl.status_code = 2
						crawl.touch
						crawl.save
						puts "I've heard that one before."
						puts gsp_page_url
					end
					
					cp2_page_url = p['href'].gsub(" ", "%20") + "?cp=2"
					if Webcrawl.where('url = ?', cp2_page_url).first.blank? then
						puts "That's a new one."
						crawl = Webcrawl.create!(:url => cp2_page_url, :source => "cdm_cp2", :last_page => i, :status_code => 1, :retries => @r)
						puts cp2_page_url, i
					else
						crawl = Webcrawl.where('url = ?', cp2_page_url).first
						crawl.status_code = 2
						crawl.touch
						crawl.save
						puts "I've heard that one before."
						puts cp2_page_url
					end

					cp3_page_url = p['href'].gsub(" ", "%20") + "?cp=3"
					if Webcrawl.where('url = ?', cp3_page_url).first.blank? then
						puts "That's a new one."
						crawl = Webcrawl.create!(:url => cp3_page_url, :source => "cdm_cp3", :last_page => i, :status_code => 1, :retries => @r)
						puts cp3_page_url, i
					else
						crawl = Webcrawl.where('url = ?', cp3_page_url).first
						crawl.status_code = 2
						crawl.touch
						crawl.save
						puts "I've heard that one before."
						puts cp3_page_url
					end
				end
					puts "Page #{i} is scanned"
			rescue Timeout::Error
				if try > 0
					puts "Page #{i} takes a bit long, let's try this again"
					try -= 1
					sleep 2
					retry
				else
					puts "Page #{i} took too long, switching to next one"
					@timed_out << i
				end
			rescue SocketError => e
				puts e.message
				puts "Most probably the internet connection is gone!"
			end
			if !@timed_out.empty? then
				puts "Search will go through timed out pages"
				@array_to_scan = @timed_out
				@timed_out = []
				cdm_link_collector(array_to_scan = @array_to_scan)
			else
				puts "No timeouts it seems! Off to next one."
			end
		end
	end
	@array_to_scan = []
	def vcs_page_finder
		try = 1
		begin
			puts "Checking for new links on VCS website!"
			vcs_timeout = Timeout::timeout(20){
				@agent.post('https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp', "X999field" => "Project ID", "X999sort" => "Desc", "X999tablenumber" => "2")
			}
			max = @agent.page.search("html body div#wrapper.project-list div#content div#content-inner div#main.clearfix div#projectList.qtable form#xxxx2 table tr[2] td[1]")[0].text.to_i
			if !Webcrawl.where(:source => "vcs").order("last_page DESC").first.nil? then
				lst = Webcrawl.where(:source => "vcs").order("last_page DESC").first.last_page.to_i
				@array_to_scan = (lst..max).to_a
				puts "Scan will start from project #{lst} and end at project #{max}"
			else
				@array_to_scan = (1..max).to_a
				puts "Scan will start from scratch"
			end
		rescue Timeout::Error
			if try > 0
				puts "VCS website doesn't respond, let's try again"
				try -= 1
				retry
			else
				sleep 10
				retry
			end
		rescue SocketError => e
			puts e.message
			puts "Most probably the internet connection is gone!"
		end
	end
	def vcs_link_collector(array_to_scan = @array_to_scan)
		link = "https://vcsprojectdatabase2.apx.com/myModule/Interactive.asp?Tab=Projects&a=2&i="
		array_to_scan.each do |i|
			vcs_proj_url = link + i.to_s
			if Webcrawl.where('url = ?', vcs_proj_url).first.blank? then
				puts "That's a new one."
				crawl = Webcrawl.create!(:url => vcs_proj_url, :source => "vcs", :last_page => i, :status_code => 1, :retries => @r)
				puts vcs_proj_url
			else
				crawl = Webcrawl.where('url = ?', vcs_proj_url).first
				crawl.status_code = 2
				crawl.touch
				crawl.save
				puts "I've heard that one before."
				puts vcs_proj_url
			end
			puts "Link #{i} is scanned"
		end
	end
	@array_to_scan = []
	def markit_page_finder
		try = 1
		begin
			puts "Checking for new links on Markit website!"
			#Load the first page into NOKOGIRI
			markit_timeout = Timeout::timeout(20){
				doc = Nokogiri::HTML(open("http://mer.markit.com/br-reg/public/index.jsp?p=1&r=&u=&scolumn=project_name&sdir=&s=cp&q="))
				#Load the list of page numbers from the drop-down box
				p = doc.css("#public-search-page").inner_text.delete "Page"
				#Identify the last page of the project table
				max = p.reverse[0..p.reverse.index(' ')-1].reverse.strip.to_i			
				@array_to_scan = (1..max).to_a
			}
		rescue Timeout::Error
			if try > 0
				puts "Markit website doesn't respond, let's try again"
				try -= 1
				retry
			else
				sleep 10
				retry
			end
		rescue SocketError => e
			puts e.message
			puts "Most probably the internet connection is gone!"			
		end
	end
	def markit_link_collector(array_to_scan = @array_to_scan)
		try = 1	
		#start the loop for the table pages
		puts "Scan will start from scratch, because it is necessary that way"
		#Define the link for changing pages in the common table
		pre_link = "http://mer.markit.com/br-reg/public/index.jsp?p="
		post_link = "&r=&u=&scolumn=project_name&sdir=&s=cp&q="
		array_to_scan.each do |i|
			begin
				#Compile the link for the first page of the table
				@table_link = pre_link + i.to_s + post_link
				#Open the first page of the table in Nokogiri
				markit_timeout = Timeout::timeout(20){
				doc = Nokogiri::HTML(open(@table_link))
				#Define the link for the project page
				proj_link = 'http://mer.markit.com/br-reg/public/project.jsp?project_id='
				#Start the loop through the project IDs on the page
				doc.css("#public-view-results a").each do |a|
					#Identify the first project ID
					proj_id = a['href'].reverse[0..14].reverse
					#Construct the full page link
					mark_proj_url = proj_link + proj_id.to_s
					if Webcrawl.where('url = ?', mark_proj_url).first.blank? then
						puts "That's a new one."
						crawl = Webcrawl.create!(:url => mark_proj_url, :source => 'mark', :last_page => i, :status_code => 1, :retries => @r)
						puts mark_proj_url
					else
						crawl = Webcrawl.where('url = ?', mark_proj_url).first
						if Time.new - crawl.created_at > 600 then
							crawl.status_code = 2
							puts "I've heard that one before."
						else
							crawl.status_code = 1
							puts "That's a new one."
						end
						crawl.touch
						crawl.save
						puts "I've heard that one before."
						puts mark_proj_url
					end
				end
			}
				puts "Page #{i} is scanned"
			rescue Timeout::Error
				if try > 0
					puts "Page #{i} takes a bit long, let's try this again"
					try -= 1
					sleep 2
					retry
				else
					puts "Page #{i} took too long, switching to next one"
					@timed_out << i
				end
			rescue OpenURI::HTTPError => ex
				if try > 0
					puts "The page #{i} seems to be missing! Let's check again."
					try -= 1
					retry
				else
					puts "Yep, the page is definitely gone!"
					@missing << @table_link
				end
			rescue SocketError => e
				puts e.message
				puts "Most probably the internet connection is gone!"				
			end
		end
		puts "These pages could not be accessed"
		puts @missing.each { |e|  e }
			if !@timed_out.empty? then
				puts "Search will go through timed out pages"
				@array_to_scan = @timed_out
				@timed_out = []
				markit_link_collector(array_to_scan)
			else
				puts "No timeouts it seems, all done then!"
			end
	end
	
	cdm_doe_link_finder
	vcs_doe_link_finder

	# vcs_page_finder
	# vcs_link_collector
	
	cdm_page_finder
	cdm_link_collector
	
	 # markit_page_finder
	 # markit_link_collector
	end
end