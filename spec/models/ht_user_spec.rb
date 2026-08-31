# frozen_string_literal: true

RSpec.describe HTRegistration do
  # `described_class` for FactoryBot
  let(:factory) { :ht_user }
  let(:test_email) { "test@default.invalid" }
  let(:test_approver) { "test-approver@default.invalid" }
  let(:test_approver_name) { "Test Approver" }

  around(:each) do |example|
    described_class.delete_all
    HTApprover.delete_all
    example.run
  end

  describe ".new" do
    it "factory creates a valid object" do
      expect(build(factory).valid?).to eq(true)
    end
  end

  describe "#approver_name" do
    context "with a known approver" do
      it "returns the approver's name" do
        create(:ht_approver, email: test_approver, name: test_approver_name)
        user = build(factory, approver: test_approver)
        expect(user.approver_name).to eq test_approver_name
      end
    end

    context "with unknown approver" do
      it "returns nil" do
        user = build(factory, approver: test_approver)
        expect(user.approver_name).to eq nil
      end
    end
  end
end
