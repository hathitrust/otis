# frozen_string_literal: true

RSpec.describe HTContact do
  let(:factory) { :ht_contact }
  let(:test_email) { "contact@default.invalid" }
  let(:test_bogus_email) { "contact#default.invalid" }
  let(:test_name) { "Contact Name" }
  let(:test_type) { HTContactType.ea_approver.id }
  let(:test_inst_id) { create(:ht_institution).id }
  # Used by the `.add_or_update` tests below
  let(:test_params) {
    {
      contact_type: test_type,
      email: test_email,
      inst_id: test_inst_id,
      name: test_name
    }
  }

  around(:each) do |example|
    described_class.delete_all
    example.run
  end

  # Shared code for testing `validates ... presence: true`
  # Call the factory with the given value for an attribute and expect valid.
  # Call the factory with `nil` and empty string, neither will be valid.
  def validates_presence(attribute, value)
    expect(build(factory, **{attribute => value}).valid?).to be true
    expect(build(factory, **{attribute => nil}).valid?).to be false
    expect(build(factory, **{attribute => ""}).valid?).to be false
  end

  describe "validations" do
    describe "contact_type" do
      it "must be present" do
        validates_presence(:contact_type, test_type)
      end
    end

    describe "email" do
      it "must be present" do
        validates_presence(:email, test_email)
      end

      it "must match email regex" do
        expect(build(factory, email: test_bogus_email).valid?).to be false
      end

      it "must be unique per contact type" do
        create(factory, email: test_email, contact_type: test_type)
        expect(build(factory, email: test_email, contact_type: test_type).valid?).to be false
      end
    end

    describe "inst_id" do
      it "must be present" do
        validates_presence(:inst_id, test_inst_id)
      end
    end

    describe "name" do
      it "must be present" do
        validates_presence(:name, test_name)
      end
    end
  end

  # Checkpoint resource id and type.
  # We just want to make sure we get something.
  describe "#resource_id" do
    it "returns a value" do
      expect(create(factory).resource_id).not_to eq nil
    end
  end

  describe "#resource_type" do
    it "returns a value" do
      expect(create(factory).resource_type).not_to eq nil
    end
  end

  describe ".add_or_update" do
    context "with no matching email + type" do
      it "creates a new contact" do
        expect {
          described_class.add_or_update(**test_params)
        }.to change { described_class.count }.by(1)
      end

      it "populates all attributes" do
        expect(described_class.where(contact_type: test_type, email: test_email).count).to eq 0
        approver = described_class.add_or_update(**test_params)
        expect(approver.attributes.except("id")).to eq test_params.stringify_keys
      end
    end

    context "with existing record at the same institution" do
      let(:existing_record) {
        {
          contact_type: test_type,
          email: test_email,
          inst_id: test_inst_id,
          name: "Existing Name"
        }
      }

      it "does not create a new contact" do
        create(factory, **existing_record)
        expect {
          described_class.add_or_update(**test_params)
        }.to change { described_class.count }.by(0)
      end

      it "updates all attributes" do
        create(factory, **existing_record)
        approver = described_class.add_or_update(**test_params)
        expect(approver.attributes.except("id")).to eq test_params.stringify_keys
      end
    end

    context "with existing record at a different institution" do
      let(:other_inst_id) { create(:ht_institution).id }
      let(:existing_record) {
        {
          contact_type: test_type,
          email: test_email,
          inst_id: other_inst_id,
          name: "Existing Name"
        }
      }

      it "raises instead of creating a new contact" do
        create(factory, **existing_record)
        expect {
          described_class.add_or_update(**test_params)
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect(described_class.count).to eq 1
      end

      it "does not change the existing contact's institution" do
        create(factory, **existing_record)
        expect {
          begin
            described_class.add_or_update(**test_params)
          rescue ActiveRecord::RecordInvalid
            nil
          end
        }.not_to change { described_class.find_by(email: test_email, contact_type: test_type).inst_id }
      end
    end
  end
end
