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

identity_providers = []
10.times do
  identity_providers << Faker::Internet.unique.url
end

10.times do
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
    expires: Faker::Time.forward,
    expire_type: %w[expiresannually expiresbiannually expirescustom90 expirescustom60].sample,
    mfa: 0,
    identity_provider: identity_providers.sample
  )
  u.iprestrict = Faker::Internet.ip_v4_address
  u.save
end

10.times do
  name = Faker::Name.unique.last_name.downcase
  domain = Faker::Internet.domain_name
  i = HTInstitution.new(
    sdrinst: name,
    inst_id: name,
    name: Faker::Educator.university,
    template: Faker::Internet.url,
    authtype: ['shibboleth', ''].sample,
    domain: domain,
    us: [0, 1].sample,
    enabled: [0, 1, 2, 3].sample,
    orph_agree: [0, 1].sample,
    entityID: identity_providers.sample,
    allowed_affiliations: '^(alum|member)@' + domain,
    shib_authncontext_class: Faker::Internet.url
  )
  i.save
end
