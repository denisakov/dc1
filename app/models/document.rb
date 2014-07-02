class Document < ActiveRecord::Base
  attr_accessible :link, :version, :short_title, :title, :process_type, :project_id
  belongs_to :project
  
  has_many :occasions, :as => :occasionable
  accepts_nested_attributes_for :occasions

  has_many :when_dates, :through => :occasions, :as => :occasionable, :source => :occasionable, :source_type => 'WhenDate'
end
