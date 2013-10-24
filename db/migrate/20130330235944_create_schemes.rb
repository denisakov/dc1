class CreateSchemes < ActiveRecord::Migration
  def change
    create_table :schemes do |t|
      t.text :desc
      t.references :project
      t.references :standard
      t.timestamps
    end
  end
end
