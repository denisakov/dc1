class Role < ActiveRecord::Base
  attr_accessible :role, :project_id, :country_id
  belongs_to :project#, :inverse_of => :project
  belongs_to :country#, :inverse_of => :country
end
