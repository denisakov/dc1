class Scheme < ActiveRecord::Base
  attr_accessible :desc, :project_id, :standard_id
  belongs_to :project
  belongs_to :standard
end
