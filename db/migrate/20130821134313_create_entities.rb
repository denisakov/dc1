class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|
      t.text :title
      t.string :short_title
      
      t.timestamps
    end
  end
end
