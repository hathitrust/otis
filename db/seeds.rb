# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

raise StandardError, "Not for production use" if Rails.env.production?

require "faker"

def create_ht_user(expires:)
  u = HTUser.new(
    userid: Faker::Internet.unique.email,
    displayname: Faker::Name.name,
    email: Faker::Internet.email,
    activitycontact: Faker::Internet.email,
    approver: @approvers.sample,
    authorizer: Faker::Internet.email,
    usertype: %w[staff external student].sample,
    role: %w[corrections cataloging ssdproxy crms quality staffdeveloper staffsysadmin replacement ssd].sample,
    access: %w[total normal].sample,
    expires: expires,
    expire_type: %w[expiresannually expiresbiannually expirescustom90 expirescustom60].sample,
    mfa: [false, true].sample
  )
  if u.mfa
    u.identity_provider = HTInstitution.enabled.where.not(shib_authncontext_class: nil).sample.entityID
  else
    u.identity_provider = HTInstitution.enabled.sample.entityID
    u.iprestrict = if rand > 0.4
      Faker::Internet.public_ip_v4_address
    elsif rand > 0.2
      "any"
    else
      "#{Faker::Internet.public_ip_v4_address}, #{Faker::Internet.public_ip_v4_address}"
    end
  end
  u.save!
  c = HTCount.new(
    userid: u.userid,
    accesscount: Faker::Number.within(range: 1..10_000),
    last_access: Faker::Time.backward,
    warned: [false, true].sample,
    certified: [false, true].sample,
    auth_requested: [false, true].sample
  )
  c.save
  create_ht_approval_request(u)
end

def create_ht_approval_request(user)
  return unless rand < 0.1

  sent = [nil, Faker::Time.backward].sample
  received = sent.nil? ? nil : [nil, sent + Faker::Number.within(range: 1..10).days].sample
  renewed = received.nil? ? nil : [nil, received + Faker::Number.within(range: 1..10).days].sample
  ar = HTApprovalRequest.new(
    id: Faker::Number.unique.number(digits: 9),
    approver: user.approver,
    userid: user.email,
    received: received,
    renewed: renewed
  )
  ar.sent = sent if sent
  ar.save!
end

def create_ht_institution(enabled)
  inst_id = Faker::Internet.unique.domain_word
  domain = inst_id + "." + Faker::Internet.domain_suffix
  HTInstitution.create(
    inst_id: inst_id,
    name: Faker::University.name,
    domain: domain,
    us: [0, 1].sample,
    enabled: enabled,
    entityID: Faker::Internet.url,
    allowed_affiliations: "^(alum|member)" + domain,
    shib_authncontext_class: [nil, Faker::Internet.url].sample,
    emergency_contact: Faker::Internet.email
  )
  inst_id
end

def create_ht_billing_member(inst_id)
  HTBillingMember.create(
    inst_id: inst_id,
    weight: Faker::Number.within(range: 0.0..1.0),
    oclc_sym: Faker::Alphanumeric.alpha(number: Faker::Number.between(from: 3, to: 5)),
    marc21_sym: Faker::Alphanumeric.alpha(number: 3).upcase,
    country_code: Faker::Address.country_code,
    status: 1
  )
end

10.times do
  inst_id = create_ht_institution(1)
  create_ht_billing_member(inst_id) if [0, 1].sample.zero?
end

2.times do
  create_ht_institution(0)
end

2.times do
  create_ht_institution(2)
end

2.times do
  create_ht_institution(3)
end

# We should simulate the typical situation in which some approvers are shared.
@approvers = Array.new(30) do
  Faker::Internet.email
end

# active users
150.times do
  create_ht_user(expires: Faker::Time.forward)
end

# expired users
5.times do
  create_ht_user(expires: Faker::Time.backward)
end
