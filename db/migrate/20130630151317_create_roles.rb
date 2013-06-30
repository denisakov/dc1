class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :role
      t.references :project
      t.references :country

      t.timestamps
    end
    add_index :roles, [:project_id, :country_id]
  end
end
