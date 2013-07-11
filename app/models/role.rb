class Role < ActiveRecord::Base
  attr_accessible :role, :project_id, :country_id
  belongs_to :project
  belongs_to :country
end
