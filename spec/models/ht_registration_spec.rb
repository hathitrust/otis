# frozen_string_literal: true

RSpec.describe HTRegistration do
  # `described_class` for FactoryBot
  let(:factory) { :ht_registration }

  around(:each) do |example|
    described_class.delete_all
    example.run
  end

  describe ".new" do
    it "factory creates a valid object" do
      expect(build(factory).valid?).to eq(true)
    end
  end

  describe "validations" do
    describe "contact_info" do
      it "must be present and match e-mail pattern" do
        expect(build(factory, contact_info: nil).valid?).to be false
        expect(build(factory, contact_info: "qwerty").valid?).to be false
        expect(build(factory, contact_info: "qwerty@default.invalid").valid?).to be true
      end
    end
  end
end
