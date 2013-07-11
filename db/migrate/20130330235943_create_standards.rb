class CreateStandards < ActiveRecord::Migration
  def change
    create_table :standards do |t|
      t.string :name
      t.references :project
      t.string :short_name
      t.timestamps
    end
  end
end
