# frozen_string_literal: true

RSpec.describe HTContactType do
  # `described_class` for FactoryBot
  let(:factory) { :ht_contact_type }
  let(:test_name) { "Contact Type Name" }
  let(:test_description) { "Contact Type Description Blah Blah Blah..." }

  around(:each) do |example|
    described_class.delete_all
    example.run
  end

  # Copied from ht_contact_spec.rb, should move to helper if used with other models.
  # Shared code for testing `validates ... presence: true`
  # Call the factory with the given value for an attribute and expect valid.
  # Call the factory with `nil` and empty string, neither will be valid.
  def validates_presence(attribute, value)
    expect(build(factory, **{attribute => value}).valid?).to be true
    expect(build(factory, **{attribute => nil}).valid?).to be false
    expect(build(factory, **{attribute => ""}).valid?).to be false
  end

  describe "validations" do
    describe "name" do
      it "must be present" do
        validates_presence(:name, test_name)
      end

      it "must be unique" do
        create(factory, name: test_name)
        expect(build(factory, name: test_name).valid?).to be false
      end
    end

    describe "description" do
      it "must be present" do
        validates_presence(:description, test_description)
      end
    end
  end

  describe ".initialize_builtin_types!" do
    it "adds the expected number of rows" do
      expect {
        described_class.initialize_builtin_types!
      }.to change { described_class.count }.by(described_class::BUILTIN_TYPES.count)
    end
  end

  describe ".ea_approver" do
    it "returns a contact type" do
      described_class.initialize_builtin_types!
      expect(described_class.ea_approver).to be_a(described_class)
    end
  end

  # FIXME: remove these when we have tests for ApplicationRecord or Otis::Authorization::Resource
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
end
