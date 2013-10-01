class CreateOccasions < ActiveRecord::Migration
  def change
    create_table :occasions do |t|
      t.text :description
      t.references :project
      t.references :country
      t.references :when_date
      t.references :document
      t.references :standard
      t.references :stakeholder

      t.timestamps
    end
  end
end
