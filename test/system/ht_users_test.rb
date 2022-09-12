require "application_system_test_case"

class HTUsersTest < ApplicationSystemTestCase
  test "visit index" do
    visit_with_login ht_users_url
    assert_selector "h1", text: "Users"
  end
end
