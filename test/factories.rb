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

    trait :mfa do
      shib_authncontext_class { 'https://refeds.org/profile/mfa' }
    end
  end
end
