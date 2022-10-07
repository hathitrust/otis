require "application_system_test_case"

class HTApprovalRequestsTest < ApplicationSystemTestCase
  test "visit index" do
    visit_with_login ht_approval_requests_url
    assert_selector "h1", text: "Approval Requests"
  end

  test "approval request workflow" do
    # HT staff with approval request authority visits users index page
    visit_with_login ht_users_url
    first("input[name='ht_users[]']").click
    # HT staff creates approval request(s)
    click_on "Create Approval Requests"
    # Approval Requests index page
    assert_selector "div.alert-success"
    assert_selector "h1", text: "Approval Requests"
    page.first("tr.success td a").click
    # HT staff edits/approves email and sends it
    click_on "SEND"
    # Show page
    # Extract approve URL from alert (only show in development/test environments)
    assert_selector "div.alert-success"
    # Success alert may have several URLs based on seeded data so we take the first one.
    link = first("div.alert-success").text.split(", ")[0].match(/http.+/)[0]

    # Approver follows link from approval e-mail
    visit link
    # TODO: make approval requests more like registrations with a confirmation button.
    # See DEV-390
    # click_on "Confirm Approval"
    assert_content "Thank you"
  end
end
