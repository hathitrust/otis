# frozen_string_literal: true

RSpec.describe HTContact do
  let(:factory) { :ht_contact }
  let(:test_email) { "contact@default.invalid" }
  let(:test_name) { "Contact Name" }
  let(:test_type) { HTContactType.ea_approver.id }
  let(:test_inst_id) { create(:ht_institution).id }

  around(:each) do |example|
    described_class.delete_all
    example.run
  end

  describe "validations" do
    describe "name" do
      it "must be present" do
        expect(build(factory, name: nil).valid?).to be false
        expect(build(factory, name: "").valid?).to be false
        expect(build(factory, name: "Test Name").valid?).to be true
      end
    end
  end

  describe ".add_or_update" do
    context "with no matching email + type" do
      it "creates a mew contact" do
        expect {
          described_class.add_or_update(
            contact_type: test_type,
            email: test_email,
            inst_id: test_inst_id,
            name: test_name
          )
        }.to change { described_class.count }.by(1)
      end

      it "populates all attributes" do
        expect(described_class.where(contact_type: test_type, email: test_email).count).to eq 0
        approver = described_class.add_or_update(
          contact_type: test_type,
          email: test_email,
          inst_id: test_inst_id,
          name: test_name
        )
        expect(approver.contact_type).to eq test_type
        expect(approver.email).to eq test_email
        expect(approver.inst_id).to eq test_inst_id
        expect(approver.name).to eq test_name
      end
    end

    context "with existing record" do
      it "does not create a mew contact" do
        create(
          factory,
          contact_type: test_type,
          email: test_email,
          inst_id: create(:ht_institution).id,
          name: "Existing Name"
        )
        expect {
          described_class.add_or_update(
            contact_type: test_type,
            email: test_email,
            inst_id: test_inst_id,
            name: test_name
          )
        }.to change { described_class.count }.by(0)
      end

      it "updates all attributes" do
        create(
          factory,
          contact_type: test_type,
          email: test_email,
          inst_id: create(:ht_institution).id,
          name: "Existing Name"
        )
        approver = described_class.add_or_update(
          contact_type: test_type,
          email: test_email,
          inst_id: test_inst_id,
          name: test_name
        )
        expect(approver.contact_type).to eq test_type
        expect(approver.email).to eq test_email
        expect(approver.inst_id).to eq test_inst_id
        expect(approver.name).to eq test_name
      end
    end
  end
end
