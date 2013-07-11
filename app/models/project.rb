class Project < ActiveRecord::Base
  attr_accessible :title, :refno, :fee, :scale
  has_many :roles, :inverse_of => :country
  has_many :countries, :through => :roles
  has_many :standards
  has_many :documents
  has_many :webcrawls
  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions
end
