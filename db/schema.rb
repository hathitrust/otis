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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 0) do

  create_table "ht_users", primary_key: "userid", id: :string, limit: 256, default: "", options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "displayname", limit: 128
    t.string "email", limit: 128
    t.string "activitycontact", limit: 128
    t.string "approver", limit: 128
    t.string "authorizer", limit: 128
    t.string "usertype", limit: 32
    t.string "role", limit: 32
    t.string "access", limit: 32, default: "normal"
    t.timestamp "expires", null: false, default: -> { 'CURRENT_TIMESTAMP' }
    t.string "expire_type", limit: 32
    t.string "iprestrict", limit: 1024
    t.boolean "mfa"
    t.string "identity_provider"
  end

end
