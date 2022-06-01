# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

raise StandardError, "Not for production use" if Rails.env.production?

ActiveRecord::Base.connection.execute("DELETE FROM ht_web.otis_registrations")

require "faker"

def create_ht_user(expires:)
  u = HTUser.new(
    userid: Faker::Internet.unique.email,
    displayname: Faker::Name.name,
    email: Faker::Internet.email,
    activitycontact: Faker::Internet.email,
    approver: @approvers.sample,
    authorizer: Faker::Internet.email,
    usertype: HTUser::USERTYPES.sample.to_s,
    role: HTUser::ROLES.sample.to_s,
    access: HTUser::ACCESSES.sample.to_s,
    expires: expires,
    expire_type: HTUser::EXPIRES_TYPES.sample,
    mfa: [false, true].sample
  )
  if u.mfa
    u.inst_id = HTInstitution.enabled.where.not(shib_authncontext_class: nil).sample.inst_id
  else
    u.inst_id = HTInstitution.enabled.sample.inst_id
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
    emergency_status: [nil, "^(faculty|staff|student)" + domain].sample,
    emergency_contact: Faker::Internet.email,
    last_update: Faker::Time.backward
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

def create_ht_contact(inst_id)
  HTContact.create(
    inst_id: inst_id,
    contact_type: HTContactType.all.sample.id,
    email: Faker::Internet.email
  )
end

def create_ht_contact_type
  HTContactType.create(
    name: Faker::Job.position,
    description: Faker::Lorem.sentence(word_count: 10)
  )
end

def create_ht_registration(inst_id)
  ticket_no = Faker::Number.between(from: 1000, to: 9999)
  reg = HTRegistration.create(
    applicant_name: Faker::Name.name,
    applicant_email: Faker::Internet.email,
    applicant_date: Faker::Date.backward(days: 180),
    auth_rep_name: Faker::Name.name,
    auth_rep_email: Faker::Internet.email,
    auth_rep_date: Faker::Date.backward(days: 180),
    hathitrust_authorizer: Faker::Internet.email,
    inst_id: inst_id,
    role: HTRegistration::ROLES.sample.to_s,
    expire_type: HTUser::EXPIRES_TYPES.sample,
    jira_ticket: "XXX-#{ticket_no}",
    mfa_addendum: [true, false].sample,
    contact_info: Faker::Internet.email
  )
  if rand < 0.5
    reg.sent = Faker::Date.backward(days: 30)
    reg.token_hash = HTRegistration.digest SecureRandom.urlsafe_base64(16)
    if rand < 0.25
      reg.received = Faker::Date.backward(days: 3)
      reg.env = {"HTTP_X_REMOTE_USER" => Faker::Internet.email}.to_json
      reg.ip_address = Faker::Internet.public_ip_v4_address
    end
    reg.save!
  end
end

HTContactType.create(
  name: "ETAS",
  description: "Emergency Temporary Access Service"
)

5.times do
  create_ht_contact_type
end

10.times do
  inst_id = create_ht_institution(1)
  create_ht_billing_member(inst_id) if [0, 1].sample.zero?
  create_ht_contact(inst_id) if [0, 1].sample.zero?
  create_ht_registration(inst_id)
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
