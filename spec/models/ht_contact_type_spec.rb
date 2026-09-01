# frozen_string_literal: true

RSpec.describe HTContactType do
  # `described_class` for FactoryBot
  let(:factory) { :ht_contact_type }

  describe ".initialize_builtin_types!" do
    it "adds rows" do
      described_class.delete_all
      expect(described_class.count).to eq 0
      described_class.initialize_builtin_types!
      expect(described_class.count).to be > 0
    end
  end

  describe ".ea_approver" do
    it "returns a contact type" do
      described_class.initialize_builtin_types!
      expect(described_class.ea_approver).to be_a(described_class)
    end
  end
end
