# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131117130508) do

  create_table "addresses", :force => true do |t|
    t.text     "desc"
    t.integer  "addressable_id"
    t.string   "addressable_type"
    t.integer  "bld_num"
    t.string   "bld_block"
    t.string   "bld_name"
    t.string   "str_name"
    t.string   "room_type"
    t.string   "room_num"
    t.string   "distr_name"
    t.string   "city_name"
    t.string   "province_name"
    t.string   "post_code"
    t.string   "region"
    t.string   "sub_region"
    t.integer  "country_id"
    t.float    "lat"
    t.float    "long"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "addresses", ["addressable_type", "addressable_id"], :name => "index_addresses_on_addressable_type_and_addressable_id"

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.string   "short_name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "documents", :force => true do |t|
    t.text     "title"
    t.string   "short_title"
    t.integer  "version"
    t.text     "link"
    t.text     "process_type"
    t.integer  "project_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "documents", ["project_id", "process_type"], :name => "index_documents_on_project_id_and_process_type"

  create_table "entities", :force => true do |t|
    t.text     "title"
    t.string   "short_title"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "occasions", :force => true do |t|
    t.text     "description"
    t.integer  "project_id"
    t.integer  "when_date_id"
    t.integer  "entity_id"
    t.boolean  "public"
    t.integer  "created_by_user_id"
    t.integer  "owner_user_id"
    t.integer  "shared_to_user_id"
    t.integer  "owner_entity_id"
    t.integer  "shared_to_entity_id"
    t.string   "occasionable_type"
    t.integer  "occasionable_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "occasions", ["created_by_user_id", "owner_user_id"], :name => "index_occasions_on_created_by_user_id_and_owner_user_id"
  add_index "occasions", ["occasionable_type", "occasionable_id"], :name => "index_occasions_on_occasionable_type_and_occasionable_id"
  add_index "occasions", ["owner_entity_id", "shared_to_entity_id"], :name => "index_occasions_on_owner_entity_id_and_shared_to_entity_id"
  add_index "occasions", ["owner_user_id", "shared_to_user_id"], :name => "index_occasions_on_owner_user_id_and_shared_to_user_id"
  add_index "occasions", ["project_id", "entity_id", "when_date_id"], :name => "index_occasions_on_project_id_and_entity_id_and_when_date_id"

  create_table "projects", :force => true do |t|
    t.text     "title"
    t.text     "refno"
    t.text     "scale"
    t.integer  "fee"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "relationships", :force => true do |t|
    t.integer  "main_proj_id"
    t.integer  "assoc_proj_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "relationships", ["assoc_proj_id"], :name => "index_relationships_on_assoc_proj_id"
  add_index "relationships", ["main_proj_id", "assoc_proj_id"], :name => "index_relationships_on_main_proj_id_and_assoc_proj_id", :unique => true
  add_index "relationships", ["main_proj_id"], :name => "index_relationships_on_main_proj_id"

  create_table "schemes", :force => true do |t|
    t.text     "desc"
    t.integer  "project_id"
    t.integer  "standard_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "stakeholders", :force => true do |t|
    t.string   "entity_role"
    t.string   "country_role"
    t.integer  "project_id"
    t.integer  "entity_id"
    t.integer  "country_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "stakeholders", ["project_id", "entity_id", "country_id"], :name => "index_stakeholders_on_project_id_and_entity_id_and_country_id"

  create_table "standards", :force => true do |t|
    t.text     "name"
    t.string   "short_name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "webcrawls", :force => true do |t|
    t.text     "html"
    t.integer  "retries"
    t.integer  "status_code"
    t.text     "source"
    t.text     "url"
    t.integer  "last_page"
    t.integer  "project_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "webcrawls", ["project_id"], :name => "index_webcrawls_on_project_id"

  create_table "when_dates", :force => true do |t|
    t.datetime "date"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "when_dates", ["date"], :name => "index_when_dates_on_date"

end
