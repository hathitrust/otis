# frozen_string_literal: true

require "test_helper"

class FinalizeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @reg = create(:ht_registration, sent: Date.today - 1.day)
  end

  def submit_confirmation(registration: @reg)
    sign_in! username: Faker::Internet.email
    get finalize_url registration.token, params: {commit: true}
  end

  test "finalize landing page has a confirmation button" do
    sign_in! username: Faker::Internet.email
    get finalize_url @reg.token
    assert_response :success
    assert_equal "new", @controller.action_name
    assert_select "input[value='Confirm Registration']"
  end

  test "finalization succeeds when form is submitted" do
    submit_confirmation
    assert_response :success
    assert_equal "new", @controller.action_name
    assert_match "confirmed for #{@reg.applicant_email}", ActionView::Base.full_sanitizer.sanitize(@response.body)
    assert_not_nil @reg.reload.received
    # Believe it or not, this is just a date comparison
    assert_equal Date.parse(@reg.reload.received.to_s).to_s, Date.parse(Time.zone.now.to_s).to_s
  end

  test "sets registration IP address" do
    submit_confirmation
    assert_not_nil @reg.reload.ip_address
  end

  test "can submit confirmation multiple times" do
    submit_confirmation
    assert_response :success
    submit_confirmation
    assert_response :success
  end

  test "logs the submitter's session" do
    submit_confirmation

    assert @reg.ht_logs.first
  end

  test "logs attributes from keycard" do
    old_keycard_mode = Keycard.config.access
    Keycard.config.access = :shibboleth

    begin
      email = Faker::Internet.email

      sign_in!

      process(:get, finalize_url(@reg.token), params: {commit: true}, headers: {"HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => email})

      log_data = @reg.ht_logs.first.data

      assert_equal email, log_data["eduPersonPrincipalName"]
      assert_equal request.remote_ip, log_data["ip_address"]
    ensure
      Keycard.config.access = old_keycard_mode
    end
  end

  test "does not log token" do
    submit_confirmation

    log_data = @reg.ht_logs.first.data
    assert_not log_data["params"].key?("token")
  end

  test "shows MFA message on success" do
    inst = create(:ht_institution, entityID: "urn:something", shib_authncontext_class: "https://refeds.org/profile/mfa")
    reg = create(:ht_registration, inst_id: inst.inst_id, sent: Date.today - 1.day, mfa_addendum: true)
    submit_confirmation(registration: reg)
    assert_equal :success_mfa, assigns[:message_type]
  end

  test "shows MFA addendum message on success" do
    inst = create(:ht_institution, entityID: nil, shib_authncontext_class: nil)
    reg = create(:ht_registration, inst_id: inst.inst_id, sent: Date.today - 1.day, mfa_addendum: true)
    submit_confirmation(registration: reg)
    assert_equal :success_mfa_addendum, assigns[:message_type]
  end

  test "shows static IP message on success" do
    inst = create(:ht_institution, entityID: nil, shib_authncontext_class: nil)
    reg = create(:ht_registration, inst_id: inst.inst_id, sent: Date.today - 1.day, mfa_addendum: false)
    submit_confirmation(registration: reg)
    assert_equal :success_static_ip, assigns[:message_type]
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

class FinalizeControllerShibbolethHeadersTest < ActionDispatch::IntegrationTest
  def setup
    @reg = create(:ht_registration, sent: Date.today - 1.day)
  end

  test "saves all and only Shibboleth ENV headers in registration.env" do
    old_keycard_mode = Keycard.config.access
    Keycard.config.access = :shibboleth
    begin
      interesting_headers = {
        "HTTP_X_REMOTE_USER" => fake_shib_id,
        "HTTP_X_SHIB_AUTHENTICATION_METHOD" => "https://refeds.org/profile/mfa",
        "HTTP_X_SHIB_AUTHNCONTEXT_CLASS" => "https://refeds.org/profile/mfa",
        "HTTP_X_SHIB_DISPLAYNAME" => Faker::Name.name,
        "HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => Faker::Internet.email,
        "HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION" => "#{Faker::Internet.email};#{Faker::Internet.email}",
        "HTTP_X_SHIB_IDENTITY_PROVIDER" => "https://shibboleth.umich.edu/idp/shibboleth",
        "HTTP_X_SHIB_MAIL" => Faker::Internet.email,
        "HTTP_X_SHIB_PERSISTENT_ID" => fake_shib_id
      }
      boring_headers = {
        "SERVER_ADDR" => Faker::Internet.public_ip_v4_address,
        "SERVER_ADMIN" => Faker::Internet.email,
        "SERVER_NAME" => Faker::Internet.domain_name,
        "SERVER_PORT" => "443",
        "SERVER_PROTOCOL" => "HTTP/1.1"
      }
      sign_in! username: Faker::Internet.email
      process(:get, finalize_url(@reg.token), params: {commit: true}, headers: interesting_headers.merge(response.headers))
      assert_response :success
      headers = @reg.reload.env
      interesting_headers.keys.each do |key|
        assert headers.key?(key)
      end
      boring_headers.keys.each do |key|
        assert !headers.key?(key)
      end
    ensure
      Keycard.config.access = old_keycard_mode
    end
  end
end
