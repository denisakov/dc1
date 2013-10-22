class CreateStakeholders < ActiveRecord::Migration
  def change
    create_table :stakeholders do |t|
      t.string :role
      t.references :project
      t.references :entity

      t.timestamps
    end
    add_index :stakeholders, [:project_id, :entity_id] 
  end
end
