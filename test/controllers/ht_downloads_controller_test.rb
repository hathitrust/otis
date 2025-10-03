# frozen_string_literal: true

require "test_helper"

class HTDownloadControllerTest < ActionDispatch::IntegrationTest
  def setup
    HTDownload.delete_all
    10.times { create(:ht_download) }
  end

  test "should get index" do
    sign_in!
    get ht_downloads_url
    assert_response :success
    assert_not_nil assigns(:date_start)
    assert_not_nil assigns(:date_end)
    assert_equal "index", @controller.action_name
    assert_match "Download Reports", @response.body
  end

  class HTDownloadControllerJSONTest < ActionDispatch::IntegrationTest
    def setup
      HTDownload.delete_all
      10.times { create(:ht_download) }
    end

    test "export list of all reports as JSON" do
      sign_in!
      get ht_downloads_url format: :json
      HTDownload.all.each do |report|
        assert_match report.htid, @response.body
        assert_match report.email, @response.body
        assert_match report.ht_hathifile.author, @response.body
        assert_match ERB::Util.json_escape(ERB::Util.html_escape(report.institution_name)), @response.body
      end
      assert_kind_of Hash, JSON.parse(@response.body)
    end
  end
end
