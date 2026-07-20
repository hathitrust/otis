# frozen_string_literal: true

RSpec.describe Otis::RegistrationMover do
  let(:test_env) { {"HTTP_X_REMOTE_USER" => "nobody@default.invalid"}.to_json }
  let(:test_ht_authorizer) { "authorizer@hathitrust.org" }
  let(:test_auth_rep) { "auth-rep@default.invalid" }

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

    context "with non-ATRS non-SSD registrant" do
      (HTRegistration::ROLES - [:atrs, :ssd]).each do |role|
        it "=#{role} uses `hathitrust_authorizer` for `user.authorizer` when present" do
          registration = create(
            :ht_registration,
            role: role.to_s,
            auth_rep_email: test_auth_rep,
            hathitrust_authorizer: test_ht_authorizer,
            env: test_env
          )
          ht_user = described_class.new(registration).ht_user
          expect(ht_user.authorizer).to eq(test_ht_authorizer)
        end
      end
    end

    context "with ATRS or SSD role" do
      [:atrs, :ssd].each do |role|
        it "=#{role} uses `auth_rep_email` for `user.authorizer`" do
          registration = create(
            :ht_registration,
            role: role.to_s,
            auth_rep_email: test_auth_rep,
            hathitrust_authorizer: test_ht_authorizer,
            env: test_env
          )
          ht_user = described_class.new(registration).ht_user
          expect(ht_user.authorizer).to eq(test_auth_rep)
        end
      end
    end
  end
end
