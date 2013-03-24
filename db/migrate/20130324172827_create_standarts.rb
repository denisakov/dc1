class CreateStandarts < ActiveRecord::Migration
  def change
    create_table :standarts do |t|
      t.string :name
      t.references :project

      t.timestamps
    end
    add_index :standarts, :project_id
  end
end
