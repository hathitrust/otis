require "application_system_test_case"

class HTApprovalRequestsTest < ApplicationSystemTestCase
  test "visit index" do
    visit_with_login ht_approval_requests_url
    assert_selector "h1", text: "Approval Requests"
  end

  test "approval request workflow" do
    # Users index page
    visit_with_login ht_users_url
    first("input[name='ht_users[]']").click
    click_on "Create Approval Requests"
    # Approval Requests index page
    assert_selector "div.alert-success"
    assert_selector "h1", text: "Approval Requests"
    page.first("tr.success td a").click
    # Approver/edit page
    click_on "SEND"
    # Show page
    # Extract approve URL from alert (only show in development/test environments)
    assert_selector "div.alert-success"
    link = first("div.alert-success").text.match(/http.+/)[0]
    # Pretend we're the recipient of the approval e-mail and follow link.
    visit link
    # TODO: make approval requests more like registrations with a confirmation button.
    # See DEV-390
    # click_on "Confirm Approval"
    assert_content "Thank you"
  end
end
