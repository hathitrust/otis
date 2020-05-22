# frozen_string_literal: true

require 'active_support/time'

FactoryBot.define do
  factory :ht_user, class: HTUser do
    sequence(:userid) { |n| "#{n}#{Faker::Internet.email}" }
    email { Faker::Internet.email }
    expire_type { ExpirationDate::EXPIRES_TYPE.keys.sample.to_s }
    expires { Faker::Time.forward }
    iprestrict { Faker::Internet.ip_v4_address }
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

  factory :ht_institution do
    sequence(:inst_id) { |n| "#{n}#{Faker::Internet.domain_word}" }
    name { Faker::University.name }
    entityID { Faker::Internet.url }
    enabled { [0, 1].sample }

    trait :mfa do
      shib_authncontext_class { 'https://refeds.org/profile/mfa' }
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
    userid { Faker::Internet.email }

    trait :expired do
      sent { Time.now - 7.days }
      token_hash { Base64.encode64(Faker::String.random(length: 32)) }
    end
  end
end
