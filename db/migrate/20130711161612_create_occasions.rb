class CreateOccasions < ActiveRecord::Migration
  def change
    create_table :occasions do |t|
      t.text :description
      t.references :project
      
      t.references :when_date
      t.references :document
      t.references :standard
      t.references :entity

      t.timestamps
    end
  end
end
