class Relationship < ActiveRecord::Base
  attr_accessible :assoc_proj_id, :main_proj_id

  belongs_to :main_proj, class_name: "Project"
  belongs_to :assoc_proj, class_name: "Project"
end
