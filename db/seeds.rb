# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

raise StandardError, 'Not for production use' if Rails.env.production?

require 'faker'

# rubocop:disable Metrics/MethodLength
def create_ht_user(expires:)
  u = HTUser.new(
    userid: Faker::Internet.email,
    displayname: Faker::Name.name,
    email: Faker::Internet.email,
    activitycontact: Faker::Internet.email,
    approver: Faker::Internet.email,
    authorizer: Faker::Internet.email,
    usertype: %w[staff external student].sample,
    role: %w[corrections cataloging ssdproxy crms quality staffdeveloper staffsysadmin replacement ssd].sample,
    access: %w[total normal].sample,
    expires: expires,
    expire_type: %w[expiresannually expiresbiannually expirescustom90 expirescustom60].sample,
    mfa: 0,
    identity_provider: HTInstitution.all.sample.entityID
  )
  u.iprestrict = Faker::Internet.ip_v4_address
  u.save
end
# rubocop:enable Metrics/MethodLength

5.times do
  HTInstitution.create(
    inst_id: Faker::Internet.domain_word,
    name: Faker::University.name,
    entityID: Faker::Internet.url
  )
end

# active users
150.times do
  create_ht_user(expires: Faker::Time.forward)
end

# expired users
5.times do
  create_ht_user(expires: Faker::Time.backward)
end
