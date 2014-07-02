class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.text :desc
      t.integer :addressable_id
      t.string :addressable_type
      t.integer :bld_num
      t.string :bld_block
      t.string :bld_name
      t.string :str_name
      t.string :room_type
      t.string :room_num
      t.string :distr_name
      t.string :city_name
      t.string :province_name
      t.string :post_code
      t.string :region
      t.string :sub_region
      t.references :country
      t.float :lat
      t.float :long

      t.timestamps
    end

    add_index :addresses, [:addressable_type, :addressable_id]
  end
end
