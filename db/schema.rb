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

ActiveRecord::Schema.define(:version => 20100527185738) do

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["locked_by"], :name => "index_delayed_jobs_on_locked_by"

  create_table "failed_twitts", :force => true do |t|
    t.string   "station_string"
    t.datetime "date"
    t.string   "user"
    t.integer  "twitter_id",     :limit => 8
    t.integer  "line_id"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "twitt_body"
  end

  create_table "incident_templates", :force => true do |t|
    t.string "comment"
  end

# Could not dump table "incidents" because of following StandardError
#   Unknown type 'long' for column 'android_id'

  create_table "line_stations", :force => true do |t|
    t.integer  "line_id"
    t.integer  "station_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "lines", :force => true do |t|
    t.string  "number"
    t.string  "name"
    t.string  "colour"
    t.float   "center_lat"
    t.float   "center_long"
    t.integer "zoom"
  end

  create_table "stations", :force => true do |t|
    t.string   "name"
    t.string   "nicename"
    t.float    "lat"
    t.float    "long"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "subscriptions", :force => true do |t|
    t.string   "email"
    t.integer  "line_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "verification_token"
  end

end
