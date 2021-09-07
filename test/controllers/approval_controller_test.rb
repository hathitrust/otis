# frozen_string_literal: true

require "test_helper"

class ApprovalControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: "approver@wherever.edu", expire_type: "expiresannually", expires: Time.zone.now)
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver, sent: Date.today - 1.day)
  end

  test "succeeds approval by approver with email not known in advance" do
    sign_in! username: Faker::Internet.email
    get approve_url @req.token
    assert_response :success
    assert_equal "new", @controller.action_name
    assert_match @req.userid, @response.body
    assert_match @req.approver, @response.body
    assert_not_nil @req.reload.received
    assert_equal Date.parse(@req.reload.received).to_s, Date.parse(Time.zone.now.to_s).to_s
  end

  test "does not show nav menu for approval with email not known in advance" do
    sign_in! username: Faker::Internet.email
    get approve_url @req.token
    assert_response :success
    assert_no_match "Home", @response.body
  end

  test "refuses to approve the same request a second time" do
    sign_in!
    get approve_url @req.token
    assert_response :success
    get approve_url @req.token
    assert_response :success
    assert_match "no longer", @response.body
  end

  test "logs the approvers session" do
    sign_in!
    get approve_url @req.token

    assert @user.ht_logs.first
  end

  test "logs attributes from keycard" do
    old_keycard_mode = Keycard.config.access
    Keycard.config.access = :shibboleth

    begin
      email = Faker::Internet.email

      sign_in!

      process(:get, approve_url(@req.token), headers: {"HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => email})

      log_data = @user.ht_logs.first.data

      assert_equal email, log_data["eduPersonPrincipalName"]
      assert_equal request.remote_ip, log_data["ip_address"]
    ensure
      Keycard.config.access = old_keycard_mode
    end
  end

  test "does not log token" do
    sign_in!

    get approve_url @req.token

    log_data = @user.ht_logs.first.data
    assert_not log_data["params"].key?("token")
  end
end

class ApprovalControllerFailureTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: "no_account@example.com")
    @user2 = create(:ht_user, approver: "nobody@example.com")
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver, sent: Date.today - 2.day)
    @req2 = create(:ht_approval_request, userid: @user2.email, approver: @user2.approver, sent: Date.today - 2.week)
  end

  test "gets 404 with nonsense token" do
    sign_in!
    get approve_url "asdfghjkl"
    assert_response :not_found
  end

  test "gets 404 with unsent approval" do
    unsent = create(:ht_approval_request)
    sign_in!
    get approve_url unsent.token
    assert_response :not_found
  end

  test "fails approval of expired request" do
    sign_in!
    get approve_url @req2.token
    assert_response :success
    assert_match "expired", @response.body
  end
end
