# frozen_string_literal: true

RSpec.describe "/ht_downloads json", type: :request do
  let(:dl_count) { 10 }

  before(:each) do
    HTDownload.delete_all
    dl_count.times { create(:ht_download) }
  end

  it "can export list of all reports as JSON" do
    sign_in!
    get ht_downloads_url(format: :json)

    HTDownload.all.each do |report|
      expect(response.body).to match(report.htid)
      expect(response.body).to match(report.email)
      expect(response.body).to match(report.ht_hathifile.author)
      expect(response.body).to match(ERB::Util.json_escape(ERB::Util.html_escape(report.institution_name)))
    end

    json_body = JSON.parse(@response.body)
    expect(json_body).to be_a_kind_of(Hash)
    expect(json_body["rows"].length).to eq(dl_count)
  end

  it "can export list of full_download=yes reports as JSON" do
    sign_in!
    get ht_downloads_url(format: :json, filter: "{\"full_download\":\"yes\"}")

    json_body = JSON.parse(@response.body)
    expect(json_body).to be_a_kind_of(Hash)
    expected = HTDownload.where(pages: nil, is_partial: 0).count
    expect(json_body["rows"].length).to eq(expected)
  end

  it "includes correctly formatted seq in partial downloads" do
    sign_in!
    get ht_downloads_url(format: :json, filter: "{\"full_download\":\"no\"}")

    json_body = JSON.parse(@response.body)
    json_body["rows"].each do |row|
      seq = row["seq"]
      expect(seq).to match(/^(\d+,)*\d+$/)
      expect(seq.split(",").count).to eq(row["pages"].to_i)
    end
  end
end
