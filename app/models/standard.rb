class Standard < ActiveRecord::Base
  attr_accessible :name, :short_name, :project_id
  belongs_to :project
  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions
end
