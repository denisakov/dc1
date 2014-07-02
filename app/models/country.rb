class Country < ActiveRecord::Base
 attr_accessible :name, :short_name
 has_many :addresses
 has_many :stakeholders

 has_many :projects, :through => :addresses, :source => :addressable, :source_type => "Project"
 has_many :entities, :through => :addresses, :source => :addressable, :source_type => "Entity"
 has_many :users, :through => :addresses, :source => :addressable, :source_type => "User"
 
end
