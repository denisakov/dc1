class Occasion < ActiveRecord::Base
  attr_accessible :description, :project_id, :country_id, :document_id, :standard_id, :when_date_id
  belongs_to :project
  belongs_to :country
  belongs_to :document
  belongs_to :standard
  belongs_to :when_date
end
