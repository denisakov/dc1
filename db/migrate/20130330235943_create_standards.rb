class CreateStandards < ActiveRecord::Migration
  def change
    create_table :standards do |t|
      t.text :name
      t.references :project
      t.string :short_name
      t.timestamps
    end
  end
end
