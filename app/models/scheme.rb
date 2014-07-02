class Scheme < ActiveRecord::Base
  attr_accessible :desc, :project_id, :standard_id
  belongs_to :project
  belongs_to :standard

  has_many :occasions, :as => :occasionable
  accepts_nested_attributes_for :occasions

  has_many :when_dates, :through => :occasions, :as => :occasionable, :source => :occasionable, :source_type => 'WhenDate'
end
