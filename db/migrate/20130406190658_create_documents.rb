class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :title
      t.integer :version
      t.text :link
      t.text :process_type
      t.datetime :issue_date
      t.references :project

      t.timestamps
    end
    add_index :documents, [:project_id, :process_type]
  end
end
