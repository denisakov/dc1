class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :title
      t.text :link
      t.text :refno
      t.integer :fee
      t.timestamps
    end
  end
end
