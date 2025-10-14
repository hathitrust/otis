# frozen_string_literal: true

RSpec.describe HTDownload do
  let(:download) { build(:ht_download) }

  around(:each) do |example|
    described_class.delete_all
    ClimateControl.modify(TEST_TMP: "") do
      example.run
    end
  end

  describe ".new" do
    it "creates a valid object" do
      expect(build(:ht_download).valid?).to eq(true)
    end

    it "saves a checksum with nonzero length" do
      download = build(:ht_download)
      download.save
      download.reload
      expect(download.sha.length).to be > 0
    end

    it "does not save an object with identical checksummed fields" do
      download = create(:ht_download)
      dupe = download.dup
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
        download.email = user.email
        download.inst_code = user.ht_institution.inst_id
        expect(download.institution_name).not_to be_nil
      end
    end
  end

  describe "#hf" do
    it "returns a hathifile" do
      build(:ht_download) do |download|
        expect(download.hf).to be_a(HTHathifile)
      end
    end
  end

  describe "#role" do
    it "has a role" do
      build(:ht_download) do |download|
        expect(download.role).to be_a(String)
      end
    end
  end

  describe "#partial?" do
    it "responds to partial?" do |download|
      build(:ht_download, is_partial: 1) do |download|
        expect(download.partial?).to be(true)
      end
    end
  end

  describe "#pages" do
    # Note: this is testing the factory
    it "has positive pages when partial" do
      build(:ht_download, is_partial: 1) do |download|
        expect(download.pages).to be >= 1
      end
    end
  end

  describe "#for_role" do
    it "returns a scope for the given role" do
      2.times do
        create(:ht_download, role: "resource_sharing")
        create(:ht_download, role: "ssdproxy")
      end

      expect(HTDownload.for_role("resource_sharing").size).to be(2)
    end
  end
end
