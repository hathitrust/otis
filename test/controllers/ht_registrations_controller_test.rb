# frozen_string_literal: true

require "test_helper"

# All tests are run logged in as ADMIN_USER unless specified otherwise.
# I.e. add tests to ensure that roles who should not access can't access.
ADMIN_USER = "admin@default.invalid"

class HTRegistrationsControllerIndexTest < ActionDispatch::IntegrationTest
  def setup
    @registration = create(:ht_registration)
    sign_in! username: ADMIN_USER
  end

  test "should get index" do
    get ht_registrations_url
    assert_response :success
    assert_equal "index", @controller.action_name
    assert_not_nil assigns(:all_registrations)
    assert_match "Current Registrations", @response.body
  end

  test "as admin, shows link for new registration" do
    get ht_registrations_url
    assert_match "registrations/new", @response.body
  end
end

class HTRegistrationsControllerShowTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @registration = create(:ht_registration, inst_id: @inst.inst_id)
    sign_in! username: ADMIN_USER
  end

  test "should get show page" do
    get ht_registration_url @registration
    assert_response :success
    assert_not_nil @registration
    assert_equal "show", @controller.action_name
  end

  test "show page should include data from registration" do
    get ht_registration_url @registration
    assert_match @registration.inst_id, @response.body
    assert_match @registration.jira_ticket, @response.body
    assert_match @registration.contact_info, @response.body
    assert_match ERB::Util.html_escape(@registration.auth_rep_name), @response.body
    assert_match @registration.auth_rep_email, @response.body
    assert_match Date.parse(@registration.auth_rep_date).year.to_s, @response.body
    assert_match ERB::Util.html_escape(@registration.applicant_name), @response.body
    assert_match @registration.applicant_email, @response.body
    assert_match Date.parse(@registration.applicant_date).year.to_s, @response.body
  end

  test "show page contains edit and delete buttons" do
    get ht_registration_url @registration
    edit_btn = %r{<a.+?>Edit</a>}
    del_btn = %r{<a.+?>Delete Registration</a>}
    assert_match(edit_btn, @response.body)
    assert_match(del_btn, @response.body)
  end

  test "received registration shows WHOIS info" do
    received_registration = create(:ht_registration, received: Time.zone.now - 1.day,
      ip_address: Faker::Internet.public_ip_v4_address, env: {})
    get ht_registration_url received_registration
    assert_match "WHOIS", @response.body
  end

  # 216.160.83.56 appears in the GeoIP test DB as Washington US
  test "received registration shows GeoIP info" do
    received_registration = create(:ht_registration, received: Time.zone.now - 1.day,
      ip_address: "216.160.83.56", env: {})
    get ht_registration_url received_registration
    assert_match "Washington", @response.body
  end

  test "received registration shows Shib env info" do
    received_registration = create(:ht_registration, received: Time.zone.now - 1.day,
      ip_address: Faker::Internet.public_ip_v4_address,
      env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json)
    get ht_registration_url received_registration
    assert_match "Principal Name", @response.body
    assert_match "Display Name", @response.body
    assert_match "Identity Provider", @response.body
    assert_match "E-mail", @response.body
    assert_match "Scoped Affiliation", @response.body
  end

  test "received registration shows IDP institution name" do
    # Use a second institution just for the entityID since the institution name
    # can provide a false negative by showing up in the "Institution" field as well
    # as the IDP detail field. THis test is only concerned with the latter.
    inst1 = create(:ht_institution)
    inst2 = create(:ht_institution, entityID: Faker::Internet.url)
    env = {"HTTP_X_REMOTE_USER" => fake_shib_id,
           "HTTP_X_SHIB_IDENTITY_PROVIDER" => inst2.entityID}
    received_registration = create(:ht_registration, inst_id: inst1.id,
      received: Time.zone.now - 1.day, ip_address: Faker::Internet.public_ip_v4_address,
      env: env.to_json)
    get ht_registration_url received_registration
    assert_match ERB::Util.html_escape(inst2.name), @response.body
  end

  # The other four Shib values are displayed verbatim
  test "received registration shows Shibboleth login values" do
    env = {"HTTP_X_SHIB_DISPLAYNAME" => "Shib display name",
           "HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => "Shib principal name",
           "HTTP_X_SHIB_MAIL" => "Shib mail",
           "HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION" => "Shib scoped affiliation"}
    received_registration = create(:ht_registration, received: Time.zone.now - 1.day,
      ip_address: Faker::Internet.public_ip_v4_address, env: env.to_json)
    get ht_registration_url received_registration
    env.each do |_k, v|
      assert_match v, @response.body
    end
  end

  test "sent registration shows edit, preview, and delete buttons" do
    sent_registration = create(:ht_registration, sent: Time.zone.now - 1.day,
      received: nil, finished: nil)
    get ht_registration_url sent_registration
    assert_match edit_ht_registration_path(sent_registration), @response.body
    assert_match preview_ht_registration_path(sent_registration), @response.body
    assert_select "a[data-method='delete']"
    assert_no_match finish_ht_registration_path(sent_registration), @response.body
  end

  test "received but not finished registration shows only edit, preview, and create user buttons" do
    sent_registration = create(:ht_registration, sent: Time.zone.now - 1.day,
      received: Time.zone.now - 1.day, finished: nil)
    get ht_registration_url sent_registration
    assert_match edit_ht_registration_path(sent_registration), @response.body
    assert_match preview_ht_registration_path(sent_registration), @response.body
    assert_select "a[data-method='delete']", false
    assert_match finish_ht_registration_path(sent_registration), @response.body
  end

  test "finished registration no longer shows edit, preview, delete, or create user buttons" do
    finished_registration = create(:ht_registration, finished: Time.zone.now - 1.day)
    get ht_registration_url finished_registration
    assert_no_match edit_ht_registration_path(finished_registration), @response.body
    assert_no_match preview_ht_registration_path(finished_registration), @response.body
    assert_select "a[data-method='delete']", false
    assert_no_match finish_ht_registration_path(finished_registration), @response.body
  end

  test "show failure notice when WHOIS lookup fails" do
    received_registration = create(:ht_registration, received: Time.zone.now - 1.day,
      ip_address: Faker::Internet.public_ip_v4_address, env: {})
    begin
      ENV["SIMULATE_WHOIS_FAILURE"] = "SIMULATE_WHOIS_FAILURE"
      get ht_registration_url received_registration
      assert_match "WHOIS data unavailable", @response.body
    ensure
      ENV.delete "SIMULATE_WHOIS_FAILURE"
    end
  end
end

class HTRegistrationsControllerCreateTest < ActionDispatch::IntegrationTest
  def setup
    sign_in! username: ADMIN_USER
  end

  test "new registration page has all the fields" do
    get new_ht_registration_url
    assert_select 'select[name="ht_registration[inst_id]"]'
    assert_match 'name="ht_registration[jira_ticket]"', @response.body
    assert_match 'name="ht_registration[contact_info]"', @response.body
    assert_match 'name="ht_registration[auth_rep_name]"', @response.body
    assert_match 'name="ht_registration[auth_rep_email]"', @response.body
    assert_match 'name="ht_registration[auth_rep_date]"', @response.body
    assert_match 'name="ht_registration[applicant_name]"', @response.body
    assert_match 'name="ht_registration[applicant_email]"', @response.body
    assert_match 'name="ht_registration[applicant_date]"', @response.body
    assert_match 'name="ht_registration[mfa_addendum]"', @response.body
  end

  test "can create" do
    params = FactoryBot.build(:ht_registration).attributes.except(
      "created_at",
      "updated_at"
    ).symbolize_keys

    HTRegistration.delete_all
    post ht_registrations_url, params: {ht_registration: params}
    assert_redirected_to %r{preview}
    assert_equal 1, HTRegistration.count
    # Shows up in log
    log = HTRegistration.first.ht_logs.first
    assert_not_nil(log.data["params"])
    assert_equal(log.data["params"]["inst_id"], params[:inst_id])
    assert_equal(log.data["params"]["jira_ticket"], params[:jira_ticket])
    assert_equal(log.data["params"]["contact_info"], params[:contact_info])
    assert_equal(log.data["params"]["auth_rep_name"], params[:auth_rep_name])
    assert_equal(log.data["params"]["auth_rep_email"], params[:auth_rep_email])
    assert_equal(log.data["params"]["auth_rep_date"], params[:auth_rep_date])
    assert_equal(log.data["params"]["applicant_name"], params[:applicant_name])
    assert_equal(log.data["params"]["applicant_email"], params[:applicant_email])
    assert_equal(log.data["params"]["applicant_date"], params[:applicant_date])
    assert_equal(log.data["params"]["mfa_addendum"], params[:mfa_addendum].to_s)
  end

  test "alerts on create failure due to missing fields" do
    params = FactoryBot.build(:ht_registration).attributes.except(
      "created_at",
      "updated_at",
      "auth_rep_name",
      "auth_rep_email",
      "auth_rep_date"
    ).symbolize_keys

    HTRegistration.delete_all
    post ht_registrations_url, params: {ht_registration: params}
    assert_equal "create", @controller.action_name
    assert_equal 0, HTRegistration.count
    assert_not_empty flash[:alert]
  end

  test "allows creation of registration for someone already in ht_users" do
    user = create(:ht_user)
    params = attributes_for(:ht_registration, applicant_email: user.email, inst_id: user.inst_id)
    HTRegistration.delete_all
    post ht_registrations_url, params: {ht_registration: params}
    assert_equal 1, HTRegistration.count
  end
end

class HTRegistrationsControllerEditTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @registration = create(:ht_registration, inst_id: @inst.inst_id)

    sign_in! username: ADMIN_USER
  end

  test "form fields are present" do
    get edit_ht_registration_url @registration
    assert_select 'select[name="ht_registration[inst_id]"]'
    assert_match 'name="ht_registration[jira_ticket]"', @response.body
    assert_match 'name="ht_registration[auth_rep_name]"', @response.body
    assert_match 'name="ht_registration[auth_rep_email]"', @response.body
    assert_match 'name="ht_registration[auth_rep_date]"', @response.body
    assert_match 'name="ht_registration[applicant_name]"', @response.body
    assert_match 'name="ht_registration[applicant_email]"', @response.body
    assert_match 'name="ht_registration[applicant_date]"', @response.body
    assert_match 'name="ht_registration[mfa_addendum]"', @response.body
    assert_match 'name="ht_registration[contact_info]"', @response.body
  end

  test "can update fields" do
    new_txt_val = "updated by test"
    new_email_val = "upd@ted.biz"

    patch ht_registration_url @registration, params: {
      ht_registration: {
        "jira_ticket" => new_txt_val,
        "contact_info" => new_email_val,
        "auth_rep_name" => new_txt_val,
        "auth_rep_email" => new_email_val,
        "applicant_name" => new_txt_val,
        "applicant_email" => new_email_val
      }
    }

    relookup = HTRegistration.find(@registration.id)

    assert_response :redirect
    assert_equal new_txt_val, relookup.jira_ticket
    assert_equal new_txt_val, relookup.auth_rep_name
    assert_equal new_email_val, relookup.auth_rep_email
    assert_equal new_txt_val, relookup.applicant_name
    assert_equal new_email_val, relookup.applicant_email
    assert_equal new_email_val, relookup.contact_info
  end

  test "fails update with bogus email" do
    bogus = "bogus_email"
    patch ht_registration_url @registration, params: {ht_registration: {"applicant_email" => bogus}}
    assert_response :success
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:alert]
    assert_not_equal bogus, HTRegistration.find(@registration.id).applicant_email
  end
end

class HTRegistrationsControllerDeleteTest < ActionDispatch::IntegrationTest
  def setup
    @registration = create(:ht_registration)
    sign_in! username: ADMIN_USER
  end

  test "delete destroys the registration" do
    reg_id = @registration.id
    delete ht_registration_url @registration
    assert_response :redirect
    assert_equal "destroy", @controller.action_name
    assert_not_empty flash[:notice]
    assert_raises ActiveRecord::RecordNotFound do
      HTRegistration.find reg_id
    end
  end
end

class HTRegistrationsControllerPreviewTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @registration = create(:ht_registration, sent: nil, received: nil)
    sign_in! username: ADMIN_USER
  end

  test "should get e-mail preview" do
    get preview_ht_registration_path @registration
    assert_response :success
    assert_equal "preview", @controller.action_name
    assert_not_nil assigns(:base_url)
    assert_not_nil assigns(:email_body)
    assert_match(/E-mail Preview/i, @response.body)
    assert_select "input[value='SEND']"
  end

  test "allow resend if the registration is expired" do
    expired_registration = create(:ht_registration, sent: Time.now - 2.week, received: nil)
    get preview_ht_registration_path expired_registration
    assert_select "input[value='SEND']", false
    assert_select "input[value='RESEND']"
  end

  test "do not give option to resend if the registration is complete" do
    complete_registration = create(:ht_registration, sent: Time.now, received: Time.now)
    get preview_ht_registration_path complete_registration
    assert_select "input[value='SEND']", false
    assert_select "input[value='RESEND']", false
  end

  test "do not give option to send if already sent and not expired" do
    sent_registration = create(:ht_registration, sent: Time.now, received: nil)
    get preview_ht_registration_path sent_registration
    assert_select "input[value='SEND']", false
    assert_select "input[value='RESEND']", false
  end
end

class HTRegistrationsControllerMailTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @registration = create(:ht_registration)
  end

  def mail_registration(registration: @registration, params: {})
    sign_in!
    # Required param for mailer
    params[:email_body] ||= "test body"
    post(mail_ht_registration_path(registration), params: params)
    assert_response :redirect
    assert_equal "mail", @controller.action_name
    follow_redirect!
  end

  test "should use provided email body" do
    test_text = Faker::Lorem.paragraph

    mail_registration params: {email_body: test_text}
    assert ActionMailer::Base.deliveries.first.body.parts.any? do |part|
      part.to_s.match? test_text
    end
  end

  test "should use provided email subject line" do
    test_subject = Faker::Lorem.sentence
    mail_registration params: {subject: test_subject}
    assert_match test_subject, ActionMailer::Base.deliveries.first.subject
  end

  test "should send mail" do
    mail_registration

    assert ActionMailer::Base.deliveries.size
  end

  test "should update request status" do
    mail_registration

    assert_not_nil @registration.reload.sent
    assert_not_nil @registration.reload[:token_hash]
    assert_equal "show", @controller.action_name
  end

  test "e-mailed token matches saved hash" do
    mail_registration

    token = ActionMailer::Base.deliveries.first.html_part.body.to_s.match(%r{finalize/([A-Za-z0-9\-_]+)})[1]
    assert_equal @registration.reload.token_hash, HTRegistration.digest(token)
  end

  test "mail substitutes applicant_name value for __NAME__ template" do
    reg = create(:ht_registration, applicant_email: "user@example.com",
      applicant_name: "Reggie McRegistrationface")
    mail_registration(registration: reg)
    assert ActionMailer::Base.deliveries.first.body.parts.any? do |part|
      part.to_s.match? reg.applicant_name
    end
  end
end

class HTRegistrationFinishTest < ActionDispatch::IntegrationTest
  def setup
    @received_registration = create(:ht_registration, received: Time.now,
      ip_address: Faker::Internet.public_ip_v4_address,
      env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json)
  end

  test "finishing registration creates and displays a new user" do
    sign_in! username: ADMIN_USER
    post(finish_ht_registration_path(@received_registration))
    assert_response :redirect
    @received_registration.reload
    assert @received_registration.finished?
    assert_not_nil HTUser.find(@received_registration.applicant_email)
    follow_redirect!
    assert_equal "edit", @controller.action_name
  end

  test "finishing registration a second time displays an error" do
    sign_in! username: ADMIN_USER
    post(finish_ht_registration_path(@received_registration))
    follow_redirect!
    post(finish_ht_registration_path(@received_registration))
    follow_redirect!
    assert_not_empty flash[:alert]
  end
end
