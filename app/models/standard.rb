class Standard < ActiveRecord::Base
  attr_accessible :name, :short_name
  
  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions

  has_many :schemes, :inverse_of => :project
  has_many :projects, :through => :schemes
end
