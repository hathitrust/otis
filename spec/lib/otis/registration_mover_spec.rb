# frozen_string_literal: true

RSpec.describe Otis::RegistrationMover do
  describe "#ht_user" do
    Otis::ServiceRole.keys.each do |role_key|
      context "with service role #{role_key}" do
        it "creates a user with an expected user_type, access, and role" do
          registration = create(
            :ht_registration,
            received: Time.now,
            ip_address: Faker::Internet.public_ip_v4_address,
            role: role_key,
            env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json
          )
          new_user = described_class.new(registration).ht_user
          expect(HTUser::ROLES.member?(new_user.role)).to eq(true)
          expect(HTUser::ACCESSES.member?(new_user.access)).to eq(true)
          expect(HTUser::USERTYPES.member?(new_user.usertype)).to eq(true)
        end
      end
    end
  end
end
