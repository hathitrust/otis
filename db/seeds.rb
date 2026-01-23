# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

raise StandardError, "Not for production use" if Rails.env.production?

ActiveRecord::Base.connection.execute("DELETE FROM ht_web.otis_approval_requests")
ActiveRecord::Base.connection.execute("DELETE FROM ht_web.otis_logs")
ActiveRecord::Base.connection.execute("DELETE FROM ht_web.otis_registrations")
ActiveRecord::Base.connection.execute("DELETE FROM otis_downloads")
ActiveRecord::Base.connection.execute("DELETE FROM hathifiles.hf")

require "faker"
UNIQUE_INST_IDS = {}
UNIQUE_EMAILS = {}
UNIQUE_HTIDS = {}

def create_ht_user(expires:)
  email = Faker::Internet.email
  UNIQUE_EMAILS[email] = true
  u = HTUser.new(
    userid: Faker::Internet.unique.email,
    displayname: Faker::Name.name,
    email: email,
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
    allowed_affiliations: "^(alum|member)@" + domain,
    shib_authncontext_class: [nil, Faker::Internet.url].sample,
    emergency_status: [nil, "^(faculty|staff|student)@" + domain].sample,
    last_update: Faker::Time.backward
  )
  UNIQUE_INST_IDS[inst_id] = true
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

def fake_env
  {
    HTTP_X_REMOTE_USER: "https://shibboleth.umich.edu/idp/shibboleth!http://www.hathitrust.org/shibboleth-sp!#{Faker::Internet.base64}",
    HTTP_X_SHIB_AUTHENTICATION_METHOD: "https://refeds.org/profile/mfa",
    HTTP_X_SHIB_AUTHNCONTEXT_CLASS: "https://refeds.org/profile/mfa",
    HTTP_X_SHIB_DISPLAYNAME: Faker::Name.name,
    HTTP_X_SHIB_EDUPERSONPRINCIPALNAME: Faker::Internet.unique.email,
    HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION: "staff@#{Faker::Internet.domain_name}",
    HTTP_X_SHIB_IDENTITY_PROVIDER: "https://shibboleth.umich.edu/idp/shibboleth",
    HTTP_X_SHIB_MAIL: Faker::Internet.unique.email,
    HTTP_X_SHIB_PERSISTENT_ID: "https://shibboleth.umich.edu/idp/shibboleth!http://www.hathitrust.org/shibboleth-sp!#{Faker::Internet.base64};https://shibboleth.umich.edu/idp/shibboleth!http://www.hathitrust.org/shibboleth-sp!#{Faker::Internet.base64}"
  }.to_json
end

def create_ht_registration
  ticket_no = Faker::Number.between(from: 1000, to: 9999)
  reg = HTRegistration.create(
    applicant_name: Faker::Name.name,
    applicant_email: Faker::Internet.email,
    applicant_date: Faker::Date.backward(days: 180),
    auth_rep_name: Faker::Name.name,
    auth_rep_email: Faker::Internet.email,
    auth_rep_date: Faker::Date.backward(days: 180),
    hathitrust_authorizer: Faker::Internet.email,
    inst_id: UNIQUE_INST_IDS.keys.sample,
    role: HTRegistration::ROLES.sample.to_s,
    expire_type: HTUser::EXPIRES_TYPES.sample,
    jira_ticket: "XXX-#{ticket_no}",
    mfa_addendum: [true, false].sample,
    contact_info: Faker::Internet.email
  )
  if rand < 0.5
    reg.sent = Faker::Date.backward(days: 30)
    reg.token_hash = HTRegistration.digest SecureRandom.urlsafe_base64(16)
    if rand < 0.5
      reg.received = Faker::Date.backward(days: 3)
      reg.env = fake_env
      reg.ip_address = Faker::Internet.public_ip_v4_address
    end
    reg.save!
  end
end

def create_download
  datetime = Faker::Time.backward
  full_download = [nil, false, true].sample

  if !full_download
    pages = rand(1..20)
    seq = (1..100).to_a.sample(pages).sort.join(",")
  end

  rep = HTDownload.create(
    in_copyright: [false, true].sample,
    yyyy: datetime.year,
    yyyymm: datetime.strftime("%Y%m"),
    datetime: datetime,
    htid: UNIQUE_HTIDS.keys.sample,
    full_download: full_download,
    pages: pages,
    seq: seq,
    role: %w[ssdproxy resource_sharing].sample,
    # FIXME: how about we make sure the email and institution code match?
    email: UNIQUE_EMAILS.keys.sample,
    inst_code: UNIQUE_INST_IDS.keys.sample
  )
  rep.save
end

def create_hathifile_entry
  htid = Faker::Alphanumeric.alpha(number: [2, 3]) + "." + Faker::Alphanumeric.alphanumeric(number: 14)
  UNIQUE_HTIDS[htid] = true
  hf = HTHathifile.create(
    htid: htid,
    access: [nil, true, false].sample,
    rights_code: ["ic", "pd", "pdus", "icus", "und"].sample,
    bib_num: Faker::Number.number(digits: 9),
    title: Faker::Book.title,
    imprint: Faker::Book.publisher + ", " + Faker::Date.between(from: "1800-01-01", to: "2000-01-01").year.to_s,
    author: Faker::Book.author,
    # the following two are just gibberish for display
    content_provider_code: Faker::Alphanumeric.alpha(number: [2, 3]),
    digitization_agent_code: Faker::Alphanumeric.alpha(number: [2, 3]),
    rights_date_used: Faker::Date.between(from: "1800-01-01", to: "2000-01-01").year.to_s
  )
  hf.save!
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

20.times do
  create_ht_registration
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

10.times do
  HTLog.create(
    objid: Faker::Number.within(range: 1..10_000),
    model: %w[HTApprovalRequest HTUser HTInstitution HTContact HTContactType HTRegistration].sample,
    time: Faker::Time.backward,
    data: '{"ip_address"=>"127.0.0.1", "user_agent"=>"WhizzyAgent", "client_ip"=>"127.0.0.1"}'
  )
end

500.times do
  create_hathifile_entry
end

100.times do
  create_download
end
