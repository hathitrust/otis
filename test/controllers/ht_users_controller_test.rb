# frozen_string_literal: true

require "test_helper"

class HTUsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = create(:ht_user)
    @user2 = create(:ht_user)
  end

  test "should get index" do
    sign_in!
    get ht_users_url
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal "index", @controller.action_name
    # assert_equal "application/x-www-form-urlencoded", @request.media_type
    assert_match "Users", @response.body
    assert_match @user1.email, @response.body
    assert_match @user2.email, @response.body
    assert_match "/ht_institutions/#{@user1.ht_institution.inst_id}", @response.body
  end

  test "shows nav menu" do
    sign_in!
    get ht_users_url
    assert_match("Approval Requests", @response.body)
  end

  test "shows renewal/request checkboxes for admin" do
    sign_in!
    get ht_users_url
    assert_select("input[type='checkbox'][name='ht_users[]']")
  end

  test "hides renewal/request checkboxes for non-admin" do
    sign_in! username: "staff@default.invalid"
    get ht_users_url
    assert_select("input[type='checkbox'][name='ht_users[]']", 0)
  end

  test "should get show page" do
    sign_in!
    get ht_user_url @user1
    assert_response :success
    assert_equal "show", @controller.action_name
    assert_not_nil assigns(:user)
    assert_match CGI.escapeHTML(@user1.email), @response.body
    assert_match CGI.escapeHTML(@user1.institution), @response.body
    assert_match "/ht_institutions/#{@user1.ht_institution.inst_id}", @response.body
  end

  test "should get show page with no iprestrict" do
    sign_in!
    user = create(:ht_user_mfa)
    assert_nil user.iprestrict
    get ht_user_url user
    assert_response :success
    assert_equal "show", @controller.action_name
  end

  test "should get edit page" do
    sign_in!
    get edit_ht_user_url @user1
    assert_response :success
    assert_equal "edit", @controller.action_name
  end

  test "edit IP address succeeds" do
    sign_in!
    patch ht_user_url @user1, params: {"ht_user" => {"iprestrict" => "33.33.33.33", "mfa" => "0"}}
    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_user_path(@user1.email)
    follow_redirect!
    assert_match "33.33.33.33", @response.body
    assert_equal '^33\.33\.33\.33$', HTUser.find(@user1.email)[:iprestrict]
  end

  test "edit user is logged" do
    sign_in!
    patch ht_user_url @user1, params: {"ht_user" => {"iprestrict" => "33.33.33.33"}}
    assert_equal("33.33.33.33", @user1.ht_logs.last.data["params"]["iprestrict"])
  end

  test "edit user does not log extraneous params" do
    sign_in!
    patch ht_user_url @user1, params: {"ht_user" => {"iprestrict" => "33.33.33.33",
                                                     "nonsense" => "should not be logged"}}
    assert_nil(@user1.ht_logs.last.data["params"]["nonsense"])
  end

  test "failed edit is not logged" do
    sign_in!
    patch ht_user_url @user1, params: {"ht_user" => {"iprestrict" => "invalid"}}
    assert_nil(@user1.ht_logs.last)
  end

  test "with malformed IP address, edit IP address fails" do
    user = create(:ht_user, iprestrict: "1.2.3.4")
    sign_in!
    patch ht_user_url user, params: {"ht_user" => {"iprestrict" => "33.33.33.blah"}}
    assert_response :success
    assert_equal "update", @controller.action_name
    assert_match "valid IPv4 address", flash[:alert]
    assert_match "1.2.3.4", @response.body
  end

  test "removing IP restriction succeeds" do
    sign_in!
    patch ht_user_url @user1, params: {"ht_user" => {"iprestrict" => "any"}}
    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_user_path(@user1.email)
    follow_redirect!
    assert_equal "^.*$", HTUser.find(@user1.email)[:iprestrict]
  end

  test "updating expiration for mfa user retains nil iprestrict" do
    user = create(:ht_user_mfa)
    sign_in!
    patch ht_user_url user, params: {"ht_user" => {"expires" => Date.today.to_s}}
    assert_redirected_to ht_user_path(user.email)
    assert_nil HTUser.find(user.email)[:iprestrict]
  end

  test "setting MFA unsets iprestrict" do
    user = create(:ht_user, :inst_mfa, mfa: false, iprestrict: "33.33.33.33")
    sign_in!
    patch ht_user_url user, params: {"ht_user" => {"mfa" => "1"}}
    assert_redirected_to ht_user_path(user.email)
    assert HTUser.find(user.email)[:mfa]
    assert_nil HTUser.find(user.email)[:iprestrict]
  end

  test "active users separated from expired users" do
    active = create(:ht_user, :active)
    expired = create(:ht_user, :expired)

    sign_in!
    get ht_users_url

    assert_match(/Active Users.*#{active.email}.*Expired Users.*#{expired.email}/m, @response.body)
  end

  test "users sorted by institution" do
    create(:ht_user, ht_institution: create(:ht_institution, name: "Zebra College"))
    create(:ht_user, ht_institution: create(:ht_institution, name: "Aardvark University"))

    sign_in!
    get ht_users_url

    assert_match(/Aardvark.*Zebra/m, @response.body)
  end

  test "Expiring soon user marked" do
    # Make at least one user who's expiring soon
    create(:ht_user, email: "user@nowhere.com", expires: (Date.today + 10).to_s)
    sign_in!
    get ht_users_url
    # look for the class name
    assert_match("bg-warning", @response.body)
    assert_match("Expiring Soon", @response.body)
  end
end

class HTUsersControllerEditTest < ActionDispatch::IntegrationTest
  def setup
    HTUser.delete_all
    HTInstitution.delete_all
    sign_in!
  end

  test "Editable fields present" do
    user = create(:ht_user, expires: (Date.today + 10).to_s)
    get edit_ht_user_url user
    editable_fields = %w[approver iprestrict expires]
    editable_fields.each do |ef|
      assert_match(/name="ht_user\[#{ef}\]"/, @response.body)
    end
  end

  test "iprestrict disabled for MFA user" do
    user = create(:ht_user_mfa)
    get edit_ht_user_url user
    assert_select "input#ht_user_iprestrict" do |input|
      assert input.attr("disabled").present?
    end
  end

  test "mfa not editable for user from institution without mfa available" do
    user = create(:ht_user)
    patch ht_user_url user, params: {"ht_user" => {"mfa" => true}}
    assert_response :success
    assert_match %r{must be blank}i, flash[:alert]
    assert_nil HTUser.find(user.email)[:mfa]
  end

  test "mfa checkbox not present for institituion without MFA available" do
    user = create(:ht_user)
    get edit_ht_user_url user
    assert_select "input#mfa_checkbox", 0
  end
end

class HTUsersControllerRenewalTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = create(:ht_user)
    @user2 = create(:ht_user)
    @req1 = create(:ht_approval_request, userid: @user1.email)
  end

  test "renewing user renews approval request" do
    sign_in!
    patch ht_user_url @user1, params: {"ht_user" => {"expires" => (Date.today + 3.years).to_s}}
    assert_redirected_to ht_user_path(@user1.email)
    assert_not_nil @req1.reload.renewed
    assert_equal Date.parse(@req1.reload.renewed).to_s, Date.parse(Time.zone.now.to_s).to_s
  end

  test "renewing user creates new renewal request with staff approver if none existing" do
    sign_in!
    patch ht_user_url @user2, params: {"ht_user" => {"expires" => (Date.today + 3.years).to_s}}
    @req2 = HTApprovalRequest.where(userid: @user2.email).first
    assert_not_nil @req2
    assert_equal "admin@default.invalid", @req2.approver
    assert_equal Date.parse(@req2.renewed).to_s, Date.parse(Time.zone.now.to_s).to_s
  end

  test "renewing user manually sets expiration to the submitted date" do
    sign_in!
    new_date = (Time.zone.now + 3.years)
    patch ht_user_url @user2, params: {"ht_user" => {"expires" => new_date.to_s}}
    @user2.reload
    assert_equal new_date.to_date, @user2.expires.to_date
  end
end

class HTUsersControllerCSVTest < ActionDispatch::IntegrationTest
  def setup
    @inst1 = create(:ht_institution, inst_id: "X", name: "Y")
    @user1 = HTUser.new(userid: "a@b", displayname: "A B", email: "c@d",
      activitycontact: "e@f", approver: "g@h",
      authorizer: "i@j", usertype: "staff", role: "ssd",
      access: "total", expires: "2020-01-01 00:00:00",
      expire_type: "expiresannually", iprestrict: "any",
      mfa: false, identity_provider: "http://example.com", inst_id: "X")
    @user1.save!
    @user2 = create(:ht_user, :expired, userid: "y@z", role: :crms)
  end

  test "export list of all users as CSV" do
    sign_in!
    get ht_users_url format: :csv
    assert_equal 3, @response.body.lines.count
    assert_equal @response.body.lines[0].strip,
      "userid,displayname,email,activitycontact,approver," \
      "authorizer,usertype,role,access,expires,expire_type," \
      "iprestrict,mfa,identity_provider,inst_id,inst_name", @response.body
    assert_match "a@b,A B,c@d,e@f,g@h,i@j,staff,ssd,total,2020-01-01 00:00:00 UTC," \
                 "expiresannually,^.*$,false,http://example.com,X,Y", @response.body
  end

  test "export list of non-ATRS users as CSV" do
    sign_in!
    get ht_users_url format: :csv, role_filter: [:ssd, :ssdproxy]
    assert_equal 2, @response.body.lines.count
    assert_equal @response.body.lines[0].strip,
      "userid,displayname,email,activitycontact,approver," \
      "authorizer,usertype,role,access,expires,expire_type," \
      "iprestrict,mfa,identity_provider,inst_id,inst_name", @response.body
    roles = @response.body.lines[1..].map { |line| line.split(",")[7] }
    refute roles.include? :ssd
  end
end

class HTUsersControllerRolesTest < ActionDispatch::IntegrationTest
  test "Admin user can see ht_users index" do
    sign_in! username: "staff@default.invalid"
    get ht_users_url
    assert_response 200
  end

  test "Staff user can see ht_users indexe" do
    sign_in! username: "staff@default.invalid"
    get ht_users_url
    assert_response 200
  end

  test "Institutions-only user can only see ht_institutions index" do
    sign_in! username: "institution@default.invalid"
    get ht_users_url
    assert_response 403
  end

  test 'Admin permission shows "Create Approval Requests" and "Renew Selected Users" buttons' do
    sign_in! username: "admin@default.invalid"
    get ht_users_url
    assert_select "button.btn-primary", 2
  end

  test 'Staff permission hides "Create Approval Requests" and "Renew Selected Users" buttons' do
    sign_in! username: "staff@default.invalid"
    get ht_users_url
    assert_select "button.btn-primary", false
  end
end
