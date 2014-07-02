class CreateRelationships < ActiveRecord::Migration
  def change
    create_table :relationships do |t|
      t.integer :main_proj_id
      t.integer :assoc_proj_id

      t.timestamps
    end
    add_index :relationships, :main_proj_id
    add_index :relationships, :assoc_proj_id
    add_index :relationships, [:main_proj_id, :assoc_proj_id], unique: true
  end
end
