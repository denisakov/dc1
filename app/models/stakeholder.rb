class Stakeholder < ActiveRecord::Base
  attr_accessible :role, :project_id, :entity_id
  belongs_to :project
  belongs_to :entity
end
