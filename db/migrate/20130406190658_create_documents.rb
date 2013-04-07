class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :title
      t.text :link
      t.datetime :issue_date
      t.integer :project_id

      t.timestamps
    end
  end
end
