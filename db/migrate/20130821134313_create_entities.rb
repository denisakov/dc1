class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|
      t.text :title
      t.string :short_title
      t.references :country

      t.timestamps
    end
    add_index :entities, :country_id
  end
end
