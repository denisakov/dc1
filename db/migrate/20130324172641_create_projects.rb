class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :title
      t.text :refno
      t.text :scale
      t.integer :fee
      t.timestamps
    end
  end
end
