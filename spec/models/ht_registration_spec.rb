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

    describe "hathitrust_authorizer" do
      context "with ssd and ssdproxy roles" do
        it "may be absent but must match e-mail pattern if present" do
          [:ssd, :ssdproxy].each do |role|
            expect(build(factory, hathitrust_authorizer: nil, role: role).valid?).to be true
            expect(build(factory, hathitrust_authorizer: "qwerty", role: role).valid?).to be false
            expect(build(factory, hathitrust_authorizer: "qwerty@default.invalid").valid?).to be true
          end
        end
      end

      context "with other roles" do
        it "must be present and match e-mail pattern" do
          (HTRegistration::ROLES - [:ssd, :ssdproxy]).each do |role|
            expect(build(factory, hathitrust_authorizer: nil, role: role).valid?).to be false
            expect(build(factory, hathitrust_authorizer: "qwerty", role: role).valid?).to be false
            expect(build(factory, hathitrust_authorizer: "qwerty@default.invalid").valid?).to be true
          end
        end
      end
    end

    describe "hathitrust_authorizer_name" do
      context "with ssd and ssdproxy roles" do
        it "may be absent" do
          [:ssd, :ssdproxy].each do |role|
            expect(build(factory, hathitrust_authorizer_name: nil, role: role).valid?).to be true
            expect(build(factory, hathitrust_authorizer_name: "qwerty", role: role).valid?).to be true
          end
        end
      end

      context "with other roles" do
        it "must be present" do
          (HTRegistration::ROLES - [:ssd, :ssdproxy]).each do |role|
            expect(build(factory, hathitrust_authorizer_name: nil, role: role).valid?).to be false
            expect(build(factory, hathitrust_authorizer_name: "qwerty", role: role).valid?).to be true
          end
        end
      end
    end
  end
end
