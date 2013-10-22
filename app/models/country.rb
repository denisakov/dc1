class Country < ActiveRecord::Base
 attr_accessible :name
 has_many :roles, :inverse_of => :project
 has_many :projects, :through => :roles
 
end
