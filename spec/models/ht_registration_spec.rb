# frozen_string_literal: true

RSpec.describe HTRegistration do
  let(:registration) { build(:ht_registration) }

  around(:each) do |example|
    described_class.delete_all
    example.run
  end

  describe "#service" do
    it "exposes a valid service" do
      expect(build(:ht_registration, role: "ssd").service).to be_a(Otis::Service)
    end

    it "exposes a service with the correct name" do
      expect(build(:ht_registration, role: "ssd").service.name).to eq("SSD")
    end
  end
end
