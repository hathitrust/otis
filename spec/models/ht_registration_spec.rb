# frozen_string_literal: true

RSpec.describe HTRegistration do
  let(:registration) { build(:ht_registration) }

  around(:each) do |example|
    described_class.delete_all
    example.run
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
