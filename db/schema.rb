# frozen_string_literal: true

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

raise StandardError, 'Not for production use' if Rails.env.production?

ActiveRecord::Schema.define(version: 0) do # rubocop:disable Metrics/BlockLength
  # Tables only used by otis

  create_table "ht_web.otis_approval_requests", if_not_exists: true do |t|
    t.string :approver
    t.string :userid
    t.timestamp :sent
    t.timestamp :received
    t.timestamp :renewed
    t.text :token_hash
  end

  create_table "ht_web.otis_logs", if_not_exists: true do |t|
    t.string :objid
    t.string :model
    t.timestamp :time
    t.text :data
  end

  create_table :otis_contacts do |t|
    t.string :inst_id
    t.integer :contact_type
    t.string :email
  end

  create_table :otis_contact_types do |t|
    t.string :name
    t.text :description
  end

  create_table "ht_web.otis_registrations", if_not_exists: true do |t|
    t.string :applicant_name
    t.string :applicant_email
    t.string :applicant_date
    t.string :inst_id
    t.string :jira_ticket
    t.string :role
    t.string :expire_type
    # Institution-level ATRS point of contact
    # Not preserved when registrant is moved to ht_users
    t.string :contact_info
    # Map auth_rep_email -> ht_users.approver
    t.string :auth_rep_name
    t.string :auth_rep_email
    t.string :auth_rep_date
    # Needed for CAA but not for ATRS
    # Map hathitrust_authorizer -> ht_user.authorizer
    t.string :hathitrust_authorizer
    t.boolean :mfa_addendum, default: false
    t.text :token_hash
    t.timestamp :sent
    t.timestamp :received
    t.timestamp :finished
    t.string :ip_address
    t.text :env
  end

  # Tables also used by other applications; must be kept in sync with
  # https://github.com/hathitrust/db-image

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
    t.string :identity_provider # deprecated in favor of inst_id
    t.string :inst_id
  end

  create_table :ht_institutions, id: false do |t|
    t.string :inst_id, primary_key: true
    t.string :grin_instance
    t.string :name
    t.string :template
    t.string :domain
    t.boolean :us
    t.string :mapto_inst_id
    t.string :mapto_name
    t.integer :enabled
    t.string :entityID
    t.text :allowed_affiliations
    t.string :shib_authncontext_class
    t.text :emergency_status
    t.string :emergency_contact
    t.timestamp :last_update
  end

  create_table "ht_web.ht_counts", id: false, if_not_exists: true do |t|
    t.string :userid
    t.integer :accesscount, default: 0
    t.timestamp :last_access
    t.boolean :warned, default: false
    t.boolean :certified, default: false
    t.boolean :auth_requested, default: false
  end

  create_table :ht_billing_members, id: false do |t|
    t.string :inst_id, primary_key: true
    t.string :parent_inst_id
    t.column :weight, :decimal, precision: 4, scale: 2, default: 0.00
    t.string :oclc_sym
    t.string :marc21_sym
    t.string :country_code, default: 'us'
    t.boolean :status, default: false
  end
end
