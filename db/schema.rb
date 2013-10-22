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

ActiveRecord::Schema.define(:version => 20130821134314) do

  create_table "countries", :force => true do |t|
    t.string   "name"
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
    t.integer  "country_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "entities", ["country_id"], :name => "index_entities_on_country_id"

  create_table "occasions", :force => true do |t|
    t.text     "description"
    t.integer  "project_id"
    t.integer  "when_date_id"
    t.integer  "document_id"
    t.integer  "standard_id"
    t.integer  "entity_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "projects", :force => true do |t|
    t.text     "title"
    t.text     "refno"
    t.text     "scale"
    t.integer  "fee"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "role"
    t.integer  "project_id"
    t.integer  "country_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "roles", ["project_id", "country_id"], :name => "index_roles_on_project_id_and_country_id"

  create_table "stakeholders", :force => true do |t|
    t.string   "role"
    t.integer  "project_id"
    t.integer  "entity_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "stakeholders", ["project_id", "entity_id"], :name => "index_stakeholders_on_project_id_and_entity_id"

  create_table "standards", :force => true do |t|
    t.text     "name"
    t.integer  "project_id"
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
