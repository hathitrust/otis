# frozen_string_literal: true

require "test_helper"

class HTSSDProxyReportControllerTest < ActionDispatch::IntegrationTest
  def setup
    HTSSDProxyReport.delete_all
    10.times { create(:ht_ssd_proxy_report) }
  end

  test "should get index" do
    sign_in!
    get ht_ssd_proxy_reports_url
    assert_response :success
    assert_not_nil assigns(:date_start)
    assert_not_nil assigns(:date_end)
    assert_equal "index", @controller.action_name
    assert_match "SSD Proxy Reports", @response.body
  end

  class HTSSDProxyReportControllerJSONTest < ActionDispatch::IntegrationTest
    def setup
      HTSSDProxyReport.delete_all
      10.times { create(:ht_ssd_proxy_report) }
    end

    test "export list of all reports as JSON" do
      sign_in!
      get ht_ssd_proxy_reports_url format: :json
      HTSSDProxyReport.all.each do |report|
        assert_match report.htid, @response.body
        assert_match report.email, @response.body
        assert_match report.ht_hathifile.author, @response.body
        assert_match report.institution_name, @response.body
      end
      assert_kind_of Hash, JSON.parse(@response.body)
    end
  end
end
