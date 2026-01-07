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

  describe ".all_values" do
    # Make sure we can get values for all of the columns that have a select control
    HTDownloadPresenter::DATA_FILTER_CONTROLS.each_key do |field|
      next if HTDownloadPresenter::DATA_FILTER_CONTROLS[field] != :select
      context "with #{field}" do
        it "returns an array of values" do
          expect(described_class.all_values(field)).to be_a(Array)
        end
      end
    end

    context "with an unsupported field" do
      it "raises" do
        expect {
          described_class.all_values("no such field")
        }.to raise_error(StandardError)
      end
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

  describe "#full_download" do
    it "is false when is_partial is true" do |download|
      build(:ht_download, is_partial: true) do |download|
        expect(download.full_download).to be(false)
      end
    end

    it "is true when is_partial is false" do |download|
      build(:ht_download, is_partial: false) do |download|
        expect(download.full_download).to be(true)
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

  describe "ransacker" do
    it "finds a record based on user selection" do
      now = Time.now
      create(:ht_download, datetime: now, is_partial: false) do |download|
        downloads = described_class.ransack(
          datetime_start: now.to_date.to_s,
          full_download_eq: "yes"
        ).result
        expect(downloads.count).to eq(1)
      end
    end
  end
end
