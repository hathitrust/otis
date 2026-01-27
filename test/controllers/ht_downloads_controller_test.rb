# frozen_string_literal: true

require "test_helper"

class HTDownloadsControllerTest < ActionDispatch::IntegrationTest
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
end
