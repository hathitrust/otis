# frozen_string_literal: true

FactoryBot.define do
  factory :ht_user do
    userid { Faker::Internet.email }
    email { Faker::Internet.email }
    expires { Faker::Time.forward }
    iprestrict { Faker::Internet.ip_v4_address }
    ht_institution

    trait :active

    trait :expired do
      expires { Faker::Time.backward }
    end
  end

  factory :ht_institution do
    inst_id { Faker::Internet.domain_word }
    name { Faker::University.name }
    entityID { Faker::Internet.url }
  end
end
