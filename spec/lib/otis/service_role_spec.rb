# frozen_string_literal: true

RSpec.describe Otis::ServiceRole do
  describe ".role_keys" do
    it "returns a nonempty Array" do
      expect(described_class.role_keys).to be_a(Array)
      expect(described_class.role_keys.size.positive?).to eq(true)
    end
  end

  describe ".new" do
    it "creates a #{described_class} given a valid role" do
      expect(described_class.new(:ssd)).to be_a(described_class)
    end

    it "raises if given invalid role" do
      expect {
        described_class.new(:bogus_role)
      }.to raise_error(/unknown role/)
    end

    it "can create a #{described_class} for every role" do
      described_class.role_keys.each do |role|
        expect(described_class.new(role)).to be_a(described_class)
      end
    end
  end

  describe "#service" do
    it "exposes a valid Service" do
      expect(described_class.new(:ssd).service).to be_a(Otis::Service)
    end
  end
end
