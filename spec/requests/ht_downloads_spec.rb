# frozen_string_literal: true

RSpec.describe "/ht_downloads json", type: :request do
  let(:dl_count) { 1 }

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
      expect(response.body).to include(ERB::Util.json_escape(ERB::Util.html_escape(report.institution_name)))
    end

    json_body = JSON.parse(@response.body)
    expect(json_body).to be_a_kind_of(Hash)
    expect(json_body["rows"].length).to eq(dl_count)
  end

  it "can export list of full_download=true reports as JSON" do
    sign_in!
    get ht_downloads_url(format: :json, filter: "{\"full_download\":\"true\"}")

    json_body = JSON.parse(@response.body)
    expect(json_body).to be_a_kind_of(Hash)
    expected = HTDownload.where(pages: nil, full_download: true).count
    expect(json_body["rows"].length).to eq(expected)
  end

  it "includes correctly formatted seq in partial downloads" do
    sign_in!
    get ht_downloads_url(format: :json, filter: "{\"full_download\":\"false\"}")

    json_body = JSON.parse(@response.body)
    json_body["rows"].each do |row|
      seq = row["seq"]
      expect(seq).to match(/^(\d+,)*\d+$/)
      expect(seq.split(",").count).to eq(row["pages"].to_i)
    end
  end
end

RSpec.describe "/ht_downloads csv", type: :request do
  let(:dl_count) { 1 }

  before(:each) do
    HTDownload.delete_all
    dl_count.times { create(:ht_download) }
  end

  it "exports the same fields shown on the index page, as a header row plus a data row per report" do
    sign_in!
    get ht_downloads_url(format: :csv)

    csv = CSV.parse(response.body, headers: true)
    expected_headers = HTDownloadPresenter::ALL_FIELDS.map { |field| HTDownloadPresenter.field_label(field) }
    expect(csv.headers).to eq(expected_headers)
    expect(csv.length).to eq(dl_count)

    report = HTDownload.first
    row = csv.first
    expect(row[HTDownloadPresenter.field_label(:htid)]).to eq(report.htid)
    expect(row[HTDownloadPresenter.field_label(:email)]).to eq(report.email)
    expect(row[HTDownloadPresenter.field_label(:institution_name)]).to eq(report.institution_name)
  end

  it "does not include HTML markup or escaped entities in the exported values" do
    sign_in!
    report = HTDownload.first
    report.ht_hathifile.update!(title: "Tom & Jerry's <Adventures>")

    get ht_downloads_url(format: :csv)

    expect(response.body).not_to match(/<a[ >]|<\/a>|<span[ >]|<\/span>/)
    expect(response.body).not_to include("&amp;", "&lt;", "&gt;")
    expect(response.body).to include("Tom & Jerry's <Adventures>")
  end

  it "returns a header-only CSV, rather than erroring, when no reports match the filter" do
    sign_in!
    get ht_downloads_url(format: :csv, filter: "{\"htid\":\"no-such-htid\"}")

    expect(response).to have_http_status(:ok)
    csv = CSV.parse(response.body, headers: true)
    expected_headers = HTDownloadPresenter::ALL_FIELDS.map { |field| HTDownloadPresenter.field_label(field) }
    expect(csv.headers).to eq(expected_headers)
    expect(csv.length).to eq(0)
  end
end
