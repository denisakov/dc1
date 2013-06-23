class Project < ActiveRecord::Base
  attr_accessible :title, :link, :refno, :fee
  has_many :countries
  has_many :standards
  has_many :documents
  has_many :webcrawls


end
