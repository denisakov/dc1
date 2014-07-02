class Address < ActiveRecord::Base
  attr_accessible :desc, :addressable_id, :addressable_type, :bld_num, :bld_block, :bld_name, :str_name, :room_type, :room_num, :distr_name, :city_name, :province_name, :post_code, :region, :sub_region, :country_id, :lat, :long
  belongs_to :country
  belongs_to :addressable, :polymorphic => true

  has_many :occasions, :as => :occasionable
  accepts_nested_attributes_for :occasions

  has_many :when_dates, :through => :occasions, :as => :occasionable, :source => :occasionable, :source_type => 'WhenDate'
end
