class CreateStakeholders < ActiveRecord::Migration
  def change
    create_table :stakeholders do |t|
      t.text :title
      t.string :short_title
      t.references :country

      t.timestamps
    end
    add_index :stakeholders, :country_id
  end
end
