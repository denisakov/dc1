class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|
      t.string :role
      t.references :project
      t.references :stakeholder

      t.timestamps
    end
    add_index :entities, [:project_id, :stakeholder_id] 
  end
end
