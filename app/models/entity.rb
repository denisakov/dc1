class Entity < ActiveRecord::Base
  attr_accessible :role, :project_id, :stakeholder_id
  belongs_to :project
  belongs_to :stakeholder
end
