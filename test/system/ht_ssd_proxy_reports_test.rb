require "application_system_test_case"

class HTSSDProxyReportsTest < ApplicationSystemTestCase
  test "visit index" do
    visit_with_login ht_ssd_proxy_reports_url
    assert_selector "h1", text: "SSD Proxy Reports"
  end
end
