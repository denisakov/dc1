class Document < ActiveRecord::Base
  attr_accessible :issue_date, :link, :project_id, :title
  belongs_to :project
end
