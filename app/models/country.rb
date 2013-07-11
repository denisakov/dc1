class Country < ActiveRecord::Base
 attr_accessible :name
 has_many :roles, :inverse_of => :project
 has_many :projects, :through => :roles
 has_many :occasions, :inverse_of => :when_date
 has_many :when_dates, :through => :occasions
end
