require "application_system_test_case"

class HTRegistrationsTest < ApplicationSystemTestCase
  test "visit index" do
    visit_with_login ht_registrations_url
    assert_selector "h1", text: "Current Registrations"
    assert_selector "a.btn", text: "New Registration"
  end

  test "registration workflow" do
    visit_with_login ht_registrations_url
    click_on "New Registration"
    assert_selector "h1", text: "New Registration"
    fill_in "Applicant Name", with: "Test Registration Applicant"
    fill_in "Applicant E-mail", with: "test_reg_applicant@default.invalid"
    fill_in "Applicant Date", with: "01/01/2022"
    # Select2 nastiness
    first(".select2-container").click
    first("li.select2-results__option--selectable").click
    fill_in "Ticket", with: "XXX-001"
    select "Staff Developer", from: "Role"
    select "1 year", from: "Expire Type"
    fill_in "Auth Rep Name", with: "Test Registration Auth Rep"
    fill_in "Auth Rep E-mail", with: "test_reg_auth_rep@default.invalid"
    fill_in "Auth Rep Date", with: "01/01/2022"
    fill_in "Contact Info", with: "contact_info@default.invalid"
    fill_in "HathiTrust Authorizer", with: "nobody@hathitrust.org"
    # Capybara's too dumb to find and click a checkbox
    check "ht_registration_mfa_addendum"
    click_on "Submit Changes"
    # Edit email page
    assert_selector "div.alert-success"
    assert_selector "h1", text: "Test Registration Applicant"
    assert_content "E-mail Preview"
    click_on "SEND"
    # Show page
    assert_selector "h1", text: "Test Registration Applicant"
    # Extract finalize URL from alert (only show in development/test environments)
    assert_selector "div.alert-success"
    link = first("div.alert-success").text.match(/http.+/)[0]
    # Pretend we're the recipient of the registration e-mail and follow link.
    visit link
    click_on "Confirm Registration"
    assert_content "confirmed for test_reg_applicant@default.invalid"
    reg_id = HTRegistration.where(applicant_email: "test_reg_applicant@default.invalid").first.id
    # Visit show page for new registration
    visit ht_registration_path(reg_id)
    assert_selector "h1", text: "Test Registration Applicant"
    assert_selector "a.btn-success", text: "Create User"
    click_on "Create User"
    # Error for blank user ID since at this point we don't have any ENV stored for the finished registration
    assert_selector "div.alert-danger", text: "User ID can't be blank"
  end
end
