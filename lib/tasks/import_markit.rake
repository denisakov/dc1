namespace :import do
	desc "imports data from Markit registry"
	task :markit => :environment do
	    require 'rubygems'
	    require 'open-uri'
	    require 'nokogiri'

		#Define the link for changing pages in the common table
		pre_link = "http://mer.markit.com/br-reg/public/index.jsp?p="
		page_no= 1
		post_link = "&r=&u=&scolumn=project_name&sdir=ASC&s=cp&q="
		#Load the first page into NOKOGIRI
		doc = Nokogiri::HTML(open("http://mer.markit.com/br-reg/public/index.jsp?p=1&r=&u=&scolumn=project_name&sdir=ASC&s=cp&q="))
		#Load the list of page numbers from the drop-down box
		p = doc.css("#public-search-page").inner_text.delete "Page"
		#Identify the last page of the project table
		top_page = p.reverse[0..p.reverse.index(' ')-1].reverse.strip.to_s

		#Define the link for the project page
		proj_link = "http://mer.markit.com/br-reg/public/project.jsp?project_id="

		#start the loop for the table pages
		top_page.to_i.times do
			#Compile the link for the first page of the table
			table_link = pre_link + page_no.to_s + post_link
			#Open the first page of the table in Nokogiri
			doc = Nokogiri::HTML(open(table_link))
			#Start the loop through the project IDs on the page
			doc.css("#public-view-results a").each do |a|
				#Identify the first project ID
				proj_id = a['href'][23..48].strip

				#Construct the full page link
				proj_url = proj_link + proj_id.to_s
				#Load the document into Nokogiri
				doc = Nokogiri::HTML(open(proj_url))
				#Change the encoding twice to filter out incorrect symbols
				doc.encoding = "ISO-8859-1"
				doc.encoding = "cp1252"
				#Find the internal ID of the project
				id = doc.css("#project_id")
				#Find the title of the project
				title = doc.xpath("/html/body/h1").text.sub(id.text,"").sub('*',"").strip
				#Find the full location of the project
				location = doc.css(".unitTable tr:nth-child(3) td").text
				#Extract the country name from location
				country = location.reverse[0..location.reverse.index(',')-1].reverse.strip
				#Find the name of the standard
				standard = doc.css(".unitTable tr:nth-child(2) td:nth-child(2)").text.strip
				#proj_id = doc.css("#project_id").text.delete "(ID: )"
				#Create a new project record
				project = Project.create!(:title => title, :link => proj_url)
				#Write in the country names
				project.countries.build(:name => country)
				#Write the standard name
				project.standards.build(:name => standard)
				#Grab the list of documents and loop throu it recording the titles and links
				doc.css(".doc").each do |d|
					doc_url = d['href'].strip.prepend("http://mer.markit.com")
					#Find the document id
					doc_id = doc_url.reverse[0..14].reverse.prepend(" - ")
					doc_title = doc_id.prepend(d.children.text)
					#Write project url into the database
					project.documents.build(:title => doc_title, :issue_date => "01.01.2000", :link => doc_url)
					end
				#Save the database entries
				project.save!
				puts "#{proj_id} - #{title} - #{country} - #{standard}"
				puts "#{project.documents.map{|d| d.title}}"
				sleep 0.5
			end
			page_no += 1
		end

	end
end