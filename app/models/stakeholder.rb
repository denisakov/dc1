class Stakeholder < ActiveRecord::Base
  attr_accessible :entity_role, :country_role, :project_id, :entity_id, :country_id
  belongs_to :project
  belongs_to :entity
  belongs_to :country

  has_many :occasions, :as => :occasionable
  accepts_nested_attributes_for :occasions

  has_many :when_dates, :through => :occasions, :as => :occasionable, :source => :occasionable, :source_type => 'WhenDate'
end
