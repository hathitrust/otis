# frozen_string_literal: true

RSpec.describe HTUser do
  # `described_class` for FactoryBot
  let(:factory) { :ht_user }
  let(:test_email) { "test@default.invalid" }
  let(:test_approver) { "test-approver@default.invalid" }
  let(:test_approver_name) { "Test Approver" }

  around(:each) do |example|
    described_class.delete_all
    HTContact.delete_all
    example.run
  end

  describe ".new" do
    it "factory builds a valid object" do
      expect(build(factory).valid?).to eq(true)
    end
  end

  describe "#approver_name" do
    context "with a known approver at the user's own institution" do
      it "returns the approver's name" do
        user = create(factory, approver: test_approver)
        create(:ht_contact, contact_type: HTContactType.ea_approver.id, email: test_approver,
          name: test_approver_name, inst_id: user.inst_id)
        expect(user.approver_name).to eq test_approver_name
      end
    end

    context "with unknown approver" do
      it "returns nil" do
        user = build(factory, approver: test_approver)
        expect(user.approver_name).to eq nil
      end
    end

    context "with a same-email approver contact at a different institution" do
      it "does not return the other institution's contact" do
        user = build(factory, approver: test_approver)
        create(:ht_contact, contact_type: HTContactType.ea_approver.id, email: test_approver,
          name: "Wrong Institution's Approver")
        expect(user.approver_name).to eq nil
      end
    end
  end
end
