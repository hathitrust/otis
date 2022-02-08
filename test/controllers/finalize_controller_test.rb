# frozen_string_literal: true

require "test_helper"

class FinalizeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @reg = create(:ht_registration, sent: Date.today - 1.day)
  end

  test "finalization succeeds" do
    sign_in! username: Faker::Internet.email
    get finalize_url @reg.token
    assert_response :success
    assert_equal "new", @controller.action_name
    assert_match "confirmed for #{@reg.dsp_email}", ActionView::Base.full_sanitizer.sanitize(@response.body)
    assert_not_nil @reg.reload.received
    # Believe it or not, this is just a date comparison
    assert_equal Date.parse(@reg.reload.received.to_s).to_s, Date.parse(Time.zone.now.to_s).to_s
  end

  test "does not show nav menu" do
    sign_in! username: Faker::Internet.email
    get finalize_url @reg.token
    assert_response :success
    assert_no_match "Home", @response.body
  end

  test "refuses to reprocess a finalized registration" do
    sign_in!
    get finalize_url @reg.token
    assert_response :success
    get finalize_url @reg.token
    assert_response :success
    assert_match "no longer", @response.body
  end

  test "logs the submitter's session" do
    sign_in!
    get finalize_url @reg.token

    assert @reg.ht_logs.first
  end

  test "logs attributes from keycard" do
    old_keycard_mode = Keycard.config.access
    Keycard.config.access = :shibboleth

    begin
      email = Faker::Internet.email

      sign_in!

      process(:get, finalize_url(@reg.token), headers: {"HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => email})

      log_data = @reg.ht_logs.first.data

      assert_equal email, log_data["eduPersonPrincipalName"]
      assert_equal request.remote_ip, log_data["ip_address"]
    ensure
      Keycard.config.access = old_keycard_mode
    end
  end

  test "does not log token" do
    sign_in!

    get finalize_url @reg.token

    log_data = @reg.ht_logs.first.data
    assert_not log_data["params"].key?("token")
  end

  test "references MFA addendum on success" do
    sign_in! username: Faker::Internet.email
    mfa_reg = create(:ht_registration, sent: Date.today - 1.day, mfa_addendum: true)
    get finalize_url mfa_reg.token
    assert_match "mult-factor authentication", @response.body
  end

  test "references static IP on success" do
    sign_in! username: Faker::Internet.email
    ip_reg = create(:ht_registration, sent: Date.today - 1.day, mfa_addendum: false)
    get finalize_url ip_reg.token
    assert_match "static IP address", @response.body
  end
end

class FinalizeControllerFailureTest < ActionDispatch::IntegrationTest
  def setup
    @reg = create(:ht_registration, sent: Date.today - 2.day)
    @unsent = create(:ht_registration)
    @expired = create(:ht_registration, sent: Date.today - 2.week)
  end

  test "gets 404 with nonsense token" do
    sign_in!
    get finalize_url "asdfghjkl"
    assert_response :not_found
  end

  test "gets 404 with unsent approval" do
    sign_in!
    get finalize_url @unsent.token
    assert_response :not_found
  end

  test "fails approval of expired request" do
    sign_in!
    get finalize_url @expired.token
    assert_response :success
    assert_match "expired", @response.body
  end
end
