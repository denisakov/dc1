class Stakeholder < ActiveRecord::Base
  attr_accessible :short_title, :title, :country_id
  belongs_to :country

  has_many :entities, :inverse_of => :project
  has_many :projects, :through => :entities

  has_many :occasions, :inverse_of => :when_date
  has_many :when_dates, :through => :occasions
end
