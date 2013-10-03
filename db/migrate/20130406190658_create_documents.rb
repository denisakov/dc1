class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.text :title
      t.string :short_title
      t.integer :version
      t.text :link
      t.text :process_type
      t.references :project

      t.timestamps
    end
    add_index :documents, [:project_id, :process_type]
  end
end
