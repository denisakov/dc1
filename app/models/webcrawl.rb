class Webcrawl < ActiveRecord::Base
  attr_accessible :html, :last_page, :source, :project_id, :retries, :status_code, :url
  belongs_to :project
end
