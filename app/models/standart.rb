class Standart < ActiveRecord::Base
  belongs_to :project
  has_one :project
  attr_accessible :name, :project
end
