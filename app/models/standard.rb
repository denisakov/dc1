class Standard < ActiveRecord::Base
  attr_accessible :name, :short_name, :project_id
  belongs_to :project
end
