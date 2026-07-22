# frozen_string_literal: true

RSpec.describe HTRegistration do
  let(:registration) { build(:ht_registration) }

  around(:each) do |example|
    described_class.delete_all
    example.run
  end

  describe ".new" do
    context "without an authorizer" do
      it "is valid only for ssd and atrs roles" do
        expect(build(:ht_registration, role: :ssd, hathitrust_authorizer: nil)).to be_valid
        expect(build(:ht_registration, role: :atrs, hathitrust_authorizer: nil)).to be_valid
      end

      (described_class::ROLES - [:ssd, :atrs]).each do |role|
        it "is not valid for non-atrs non-ssd role #{role}" do
          expect(build(:ht_registration, role: role, hathitrust_authorizer: nil)).not_to be_valid
        end
      end
    end
  end

  describe "#service" do
    it "exposes a valid service role" do
      expect(build(:ht_registration, role: "ssd").service_role).to be_a(Otis::ServiceRole)
    end

    it "exposes a service role with the correct name" do
      expect(build(:ht_registration, role: "ssd").service_role.name).to eq("SSD")
    end
  end
end
