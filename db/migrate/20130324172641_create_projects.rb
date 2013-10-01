class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.text :title
      t.text :refno
      t.text :scale
      t.integer :fee
      t.timestamps
    end
  end
end
