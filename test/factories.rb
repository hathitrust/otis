# frozen_string_literal: true

require "active_support/time"

FactoryBot.define do
  factory :ht_user, class: HTUser do
    sequence(:userid) { |n| "#{n}#{Faker::Internet.email}" }
    approver { Faker::Internet.email }
    email { Faker::Internet.unique.email }
    expire_type { ExpirationDate::EXPIRES_TYPE.keys.sample.to_s }
    expires { Faker::Time.forward }
    iprestrict { Faker::Internet.public_ip_v4_address }
    ht_institution

    trait :active

    trait :expired do
      expires { Faker::Time.backward }
    end

    trait :inst_mfa do
      association :ht_institution, factory: %i[ht_institution mfa]
    end

    factory :ht_user_mfa do
      inst_mfa
      mfa { true }
      iprestrict { nil }
    end
  end

  factory :ht_billing_member do
    sequence(:inst_id) { |n| "#{n}#{Faker::Internet.domain_word}" }

    weight { [0.66, 1.00, 1.33].sample }
    oclc_sym { Faker::Alphanumeric.alpha(number: 3).upcase }
    marc21_sym { Faker::Alphanumeric.alpha(number: 4).downcase }
    country_code { Faker::Address.country_code }
    status { [true, false].sample }
  end

  factory :ht_institution do
    sequence(:inst_id) { |n| "#{n}#{Faker::Internet.unique.domain_word}" }
    domain { Faker::Internet.domain_name }
    name { Faker::University.name }
    entityID { Faker::Internet.url }
    enabled { [0, 1].sample }
    us { [0, 1].sample }

    association :ht_billing_member

    trait :mfa do
      shib_authncontext_class { "https://refeds.org/profile/mfa" }
    end

    trait :disabled do
      enabled { 0 }
    end

    trait :enabled do
      enabled { 1 }
    end

    trait :private do
      enabled { 2 }
    end

    trait :social do
      enabled { 3 }
    end
  end

  factory :ht_count do
    userid { Faker::Internet.email }
    accesscount { Faker::Number.within(range: 1..10_000) }
    last_access { Faker::Time.backward }
    warned { [false, true].sample }
    certified { [false, true].sample }
    auth_requested { [false, true].sample }
  end

  factory :ht_approval_request do
    approver { Faker::Internet.email }
    ht_user

    trait :renewed do
      sent { Time.now - 10.days }
      token_hash { Base64.encode64(Faker::String.random(length: 32)) }
      renewed { Time.now }
    end

    trait :approved do
      sent { Time.now - 10.days }
      token_hash { Base64.encode64(Faker::String.random(length: 32)) }
      received { Time.now }
    end

    trait :expired do
      sent { Time.now - 10.days }
      token_hash { Base64.encode64(Faker::String.random(length: 32)) }
    end

    trait :sent do
      sent { Time.now }
      token_hash { Base64.encode64(Faker::String.random(length: 32)) }
    end

    trait :unsent do
      sent { nil }
    end
  end

  factory :ht_contact_type do
    sequence(:id) { |n| n.to_s }
    name { Faker::Lorem.unique.characters(number: 10) }
    description { Faker::Lorem.sentence(word_count: 10) }
  end

  factory :ht_contact do
    sequence(:id) { |n| n.to_s }
    email { Faker::Internet.email }
    association :ht_institution, strategy: :create
    association :ht_contact_type, strategy: :create
  end

  factory :ht_registration do
    sequence(:id) { |n| n.to_s }
    applicant_name { Faker::Name.name }
    applicant_email { Faker::Internet.email }
    applicant_date { Faker::Date.backward(days: 180) }
    jira_ticket { Faker::Alphanumeric.alpha(number: 6).upcase }
    role { HTUser::ROLES.sample.to_s }
    expire_type { HTUser::EXPIRES_TYPES.sample.to_s }
    auth_rep_name { Faker::Name.name }
    auth_rep_email { Faker::Internet.email }
    auth_rep_date { Faker::Date.backward(days: 180) }
    hathitrust_authorizer { Faker::Internet.email }
    mfa_addendum { [true, false].sample }
    contact_info { Faker::Internet.email }
    association :ht_institution, strategy: :create
  end

  factory :ht_log do
    objid { Faker::Lorem.unique.characters(number: 10) }
    model { %w[HTApprovalRequest HTUser HTInstitution HTContact HTContactType HTRegistration].sample }
    time { Faker::Time.backward }
    data { '{"action"=>"ht_contacts#update", "ip_address"=>"127.0.0.1", "params"=>{"inst_id"=>"bartoletti-bins", "contact_type"=>"7", "email"=>"rosann@hettinger.edu"}, "user_agent"=>"WhizzyAgent", "client_ip"=>"127.0.0.1"}' }
  end
end
