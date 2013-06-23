class CreateWebcrawls < ActiveRecord::Migration
  def change
    create_table :webcrawls do |t|
      t.text :html
      t.integer :retries
      t.integer :status_code
      t.text :source
      t.text :url
      t.integer :last_page
      t.integer :project_id

      t.timestamps
    end
    add_index :webcrawls, :project_id
  end
end
