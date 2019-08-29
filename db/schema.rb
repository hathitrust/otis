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
#

raise "Not for production use" if Rails.env.production?

ActiveRecord::Schema.define(version: 0) do
  create_table :ht_users, id: false do |t|
    t.string :userid, primary_key: true
    t.string :displayname
    t.string :email
    t.string :activitycontact
    t.string :approver
    t.string :authorizer
    t.string :usertype
    t.string :role
    t.string :access
    t.timestamp :expires
    t.string :expire_type
    t.string :iprestrict
    t.boolean :mfa
    t.string :identity_provider
  end

end
