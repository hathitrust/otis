# frozen_string_literal: true

RSpec.describe Otis::RegistrationMover do
  describe "#ht_user" do
    [:ssdproxy, :resource_sharing].each do |role|
      context "with #{role} role" do
        it "has 'normal' access" do
          registration = create(
            :ht_registration,
            received: Time.now,
            ip_address: Faker::Internet.public_ip_v4_address,
            role: role,
            env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json
          )
          expect(described_class.new(registration).ht_user.access).to eq "normal"
        end
      end
    end

    (HTUser::ROLES - [:ssdproxy, :resource_sharing]).each do |role|
      context "with #{role} role" do
        it "has 'total' access" do
          registration = create(
            :ht_registration,
            received: Time.now,
            ip_address: Faker::Internet.public_ip_v4_address,
            role: role,
            env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json
          )
          expect(described_class.new(registration).ht_user.access).to eq "total"
        end
      end
    end
  end
end
