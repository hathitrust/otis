# frozen_string_literal: true

RSpec.describe HTDownloadPresenter do
  around(:each) do |example|
    HTDownload.delete_all
    example.run
  end

  describe ".data_filter_data" do
    # Make sure we can get values for all of the columns that have a select control.
    # TODO: this does not check that there is any particular content for any of the fields.
    described_class::DATA_FILTER_CONTROLS.select { |_k, v| v == :select }
      .each_key do |field|
      context "with #{field}" do
        it "returns a specially formatted JSON String" do
          expect(described_class.data_filter_data(field)).to match(/^json:{.*?}$/)
        end
      end
    end

    it "displays the correct value for role" do
      create(:ht_download, role: :resource_sharing) do |download|
        data = described_class.data_filter_data(:role)
        data = JSON.parse(data.sub(/^json:/, ""))
        expect(data).to eq({"resource_sharing" => "Resource Sharing"})
      end
    end

    it "displays the correct value for full_download" do
      data = described_class.data_filter_data(:full_download)
      data = JSON.parse(data.sub(/^json:/, ""))
      expect(data).to eq({"false" => "no", "true" => "yes"})
    end
  end

  describe ".data_visible" do
    it "does not make seq visible" do
      expect(described_class.data_visible(:seq)).to be false
    end

    it "makes pages visible" do
      expect(described_class.data_visible(:pages)).to be true
    end
  end
end
