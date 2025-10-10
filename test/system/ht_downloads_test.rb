require "application_system_test_case"

class HTDownloadsTest < ApplicationSystemTestCase
  test "visit index" do
    visit_with_login ht_downloads_url
    assert_selector "h2", text: "Download Reports"
  end
end
