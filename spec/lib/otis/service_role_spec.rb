# frozen_string_literal: true

RSpec.describe Otis::ServiceRole do
  describe ".keys" do
    it "returns a nonempty Array" do
      expect(described_class.keys).to be_a(Array)
      expect(described_class.keys.size.positive?).to eq(true)
    end
  end

  describe ".for_user_role" do
    HTUser::ROLES.each do |user_role|
      it "maps HTUser role #{user_role} to a valid service role key" do
        expect(
          described_class.keys.include?(
            described_class.for_user_role(user_role).service_role
          )
        ).to eq(true)
      end
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
      described_class.keys.each do |role|
        expect(described_class.new(role)).to be_a(described_class)
      end
    end
  end
end
