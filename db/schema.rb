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

ActiveRecord::Schema.define(:version => 20130518154131) do

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "documents", :force => true do |t|
    t.string   "title"
    t.integer  "version"
    t.text     "link"
    t.datetime "issue_date"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "projects", :force => true do |t|
    t.string   "title"
    t.text     "refno"
    t.text     "scale"
    t.integer  "fee"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "standards", :force => true do |t|
    t.string   "name"
    t.string   "short_name"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "standards", ["project_id"], :name => "index_standards_on_project_id"

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

end
