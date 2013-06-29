class CreateStandards < ActiveRecord::Migration
  def change
    create_table :standards do |t|
      t.string :name
      t.string :short_name
      t.references :project
      t.timestamps
    end
    add_index :standards, :project_id
  end
end
