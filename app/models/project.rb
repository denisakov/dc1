class Project < ActiveRecord::Base
  attr_accessible :title, :link
  has_many :countries
  has_many :standards
  has_many :documents
end
