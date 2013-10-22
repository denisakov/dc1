class Entity < ActiveRecord::Base
  attr_accessible :title, :short_title, :country_id
  belongs_to :country
  
  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions
  has_many :stakeholders, :inverse_of => :projects
  has_many :projects, :through => :stakeholders
end