# frozen_string_literal: true

RSpec.describe HTRegistration do
  # `described_class` for FactoryBot
  let(:factory) { :ht_user }
  let(:test_email) { "test@default.invalid" }
  let(:test_approver_name) { "Test Approver" }

  around(:each) do |example|
    described_class.delete_all
    HTRegistration.delete_all
    example.run
  end

  describe ".new" do
    it "factory creates a valid object" do
      expect(build(factory).valid?).to eq(true)
    end
  end

  describe "#approver_name" do
    context "with existing registrations" do
      it "returns the registration's most recent approver" do
        create(:ht_registration, applicant_email: test_email, finished: Time.now - 400.days, auth_rep_name: "old")
        create(:ht_registration, applicant_email: test_email, finished: Time.now - 800.days, auth_rep_name: "older")
        create(:ht_registration, applicant_email: test_email, finished: Time.now, auth_rep_name: test_approver_name)
        user = build(factory, email: test_email)
        expect(user.approver_name).to eq test_approver_name
      end
    end

    context "with no existing registration" do
      it "returns nil" do
        user = build(:ht_user)
        expect(user.approver_name).to eq nil
      end
    end
  end
end
