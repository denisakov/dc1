class CreateWhenDates < ActiveRecord::Migration
  def change
    create_table :when_dates do |t|
      t.datetime :date, :unique => true

      t.timestamps
    end
    add_index :when_dates, :date
  end
end
