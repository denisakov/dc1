class CreateStakeholders < ActiveRecord::Migration
  def change
    create_table :stakeholders do |t|
      t.string :entity_role
      t.string :country_role
      t.references :project
      t.references :entity
      t.references :country

      t.timestamps
    end
    add_index :stakeholders, [:project_id, :entity_id, :country_id] 
  end
end
