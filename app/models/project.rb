class Project < ActiveRecord::Base
  attr_accessible :title
  has_many :countries
  has_many :standarts
end
