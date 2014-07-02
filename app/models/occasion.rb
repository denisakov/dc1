class Occasion < ActiveRecord::Base
  attr_accessible :public, :description, :project_id, :when_date_id, :entity_id, :created_by_user_id, :owner_user_id, :shared_to_user_id, :owner_entity_id, :shared_to_entity_id, :occasionable_type, :occasionable_id
  belongs_to :occasionable, :polymorphic => true

  belongs_to :project
  belongs_to :when_date
  belongs_to :entity
  belongs_to :user
  
end
