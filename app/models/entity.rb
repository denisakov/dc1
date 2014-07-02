class Entity < ActiveRecord::Base
  attr_accessible :title, :short_title

  has_many :addresses, :as => :addressable
  accepts_nested_attributes_for :addresses
  
  has_many :documents, :through => :occasions, :source => :occasionable, :source_type => "Document"
  has_many :standards, :through => :occasions, :source => :occasionable, :source_type => "Standard"
  has_many :schemes, :through => :occasions, :source => :occasionable, :source_type => "Scheme"

  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions

  has_many :stakeholders, :inverse_of => :project
  has_many :projects, :through => :stakeholders
end