class CreateOccasions < ActiveRecord::Migration
  def change
    create_table :occasions do |t|
      t.text :description
      t.references :project
      t.references :when_date
      t.references :entity
      t.boolean :public
      t.integer :created_by_user_id
      t.integer :owner_user_id
      t.integer :shared_to_user_id
      t.integer :owner_entity_id
      t.integer :shared_to_entity_id

      t.string :occasionable_type
      t.integer :occasionable_id

      t.timestamps
    end
    add_index :occasions, [:project_id, :entity_id, :when_date_id]
    add_index :occasions, [:created_by_user_id, :owner_user_id]
    add_index :occasions, [:owner_user_id, :shared_to_user_id]
    add_index :occasions, [:owner_entity_id, :shared_to_entity_id]
    add_index :occasions, [:occasionable_type, :occasionable_id] 
  end
end
