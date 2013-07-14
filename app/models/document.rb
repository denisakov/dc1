class Document < ActiveRecord::Base
  attr_accessible :link, :version, :short_title, :title, :process_type, :project_id
  belongs_to :project
  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions

end
