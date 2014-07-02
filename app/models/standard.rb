class Standard < ActiveRecord::Base
  attr_accessible :name, :short_name
  
  has_many :schemes, :inverse_of => :project
  has_many :projects, :through => :schemes

  has_many :occasions, :as => :occasionable
  accepts_nested_attributes_for :occasions
  
  has_many :when_dates, :through => :occasions, :as => :occasionable, :source => :occasionable, :source_type => 'WhenDate'
end
