# frozen_string_literal: true

RSpec.describe HTSSDProxyReport do
  let(:report) { build(:ht_ssd_proxy_report) }

  around(:each) do |example|
    described_class.delete_all
    ClimateControl.modify(TEST_TMP: "") do
      example.run
    end
  end

  describe ".new" do
    it "creates a valid object" do
      expect(build(:ht_ssd_proxy_report).valid?).to eq(true)
    end

    it "saves a checksum with nonzero length" do
      report = build(:ht_ssd_proxy_report)
      report.save
      report.reload
      expect(report.sha.length).to be > 0
    end

    it "does not save an object with identical checksummed fields" do
      report = create(:ht_ssd_proxy_report)
      dupe = report.dup
      dupe.save
      expect(dupe.persisted?).to eq false
    end
  end

  describe ".ransackable_attributes" do
    it "returns an Array" do
      expect(described_class.ransackable_attributes).to be_a(Array)
    end
  end

  describe ".ransackable_associations" do
    it "returns an Array" do
      expect(described_class.ransackable_associations).to be_a(Array)
    end
  end

  describe "#institution_name" do
    it "does something" do
      create(:ht_user) do |user|
        report.email = user.email
        report.inst_code = user.ht_institution.inst_id
        expect(report.institution_name).not_to be_nil
      end
    end
  end

  describe "#hf" do
    it "returns a hathifile" do
      build(:ht_ssd_proxy_report) do |rep|
        expect(rep.hf).to be_a(HTHathifile)
      end
    end
  end
end
