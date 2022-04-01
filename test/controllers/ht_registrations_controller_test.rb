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

  test "index is well-formed HTML" do
    check_w3c_errs do
      get ht_registrations_url
    end
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

  test "show page is well-formed HTML" do
    check_w3c_errs do
      get ht_registration_url @registration
    end
  end

  test "show page should include data from registration" do
    get ht_registration_url @registration
    assert_match @registration.inst_id, @response.body
    assert_match @registration.jira_ticket, @response.body
    assert_match @registration.contact_info, @response.body
    assert_match ERB::Util.html_escape(@registration.auth_rep_name), @response.body
    assert_match @registration.auth_rep_email, @response.body
    assert_match Date.parse(@registration.auth_rep_date).year.to_s, @response.body
    assert_match ERB::Util.html_escape(@registration.dsp_name), @response.body
    assert_match @registration.dsp_email, @response.body
    assert_match Date.parse(@registration.dsp_date).year.to_s, @response.body
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
      ip_address: Faker::Internet.public_ip_v4_address)
    get ht_registration_url received_registration
    assert_match "WHOIS", @response.body
  end

  test "received registration shows Shib env info" do
    received_registration = create(:ht_registration, received: Time.zone.now - 1.day,
      env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json)
    get ht_registration_url received_registration
    assert_match "<strong>HTTP_X_REMOTE_USER</strong>", @response.body
  end

  test "finished registration no longer shows edit, mail, delete, or finish buttons" do
    finished_registration = create(:ht_registration, finished: Time.zone.now - 1.day)
    get ht_registration_url finished_registration
    assert_no_match edit_ht_registration_path(finished_registration), @response.body
    assert_no_match preview_ht_registration_path(finished_registration), @response.body
    assert_no_match ht_registration_path(finished_registration, method: :delete), @response.body
    assert_no_match finish_ht_registration_path(finished_registration, method: :post), @response.body
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
    assert_match 'name="ht_registration[dsp_name]"', @response.body
    assert_match 'name="ht_registration[dsp_email]"', @response.body
    assert_match 'name="ht_registration[dsp_date]"', @response.body
    assert_match 'name="ht_registration[mfa_addendum]"', @response.body
  end

  test "can create" do
    params = FactoryBot.build(:ht_registration).attributes.except(
      "created_at",
      "updated_at"
    ).symbolize_keys

    HTRegistration.delete_all
    post ht_registrations_url, params: {ht_registration: params}
    assert_redirected_to /preview/
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
    assert_equal(log.data["params"]["dsp_name"], params[:dsp_name])
    assert_equal(log.data["params"]["dsp_email"], params[:dsp_email])
    assert_equal(log.data["params"]["dsp_date"], params[:dsp_date])
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
end

class HTRegistrationsControllerEditTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @registration = create(:ht_registration, inst_id: @inst.inst_id)

    sign_in! username: ADMIN_USER
  end

  test "edit page is well-formed HTML" do
    check_w3c_errs do
      get edit_ht_registration_url @registration
    end
  end

  test "form fields are present" do
    get edit_ht_registration_url @registration
    assert_select 'select[name="ht_registration[inst_id]"]'
    assert_match 'name="ht_registration[jira_ticket]"', @response.body
    assert_match 'name="ht_registration[auth_rep_name]"', @response.body
    assert_match 'name="ht_registration[auth_rep_email]"', @response.body
    assert_match 'name="ht_registration[auth_rep_date]"', @response.body
    assert_match 'name="ht_registration[dsp_name]"', @response.body
    assert_match 'name="ht_registration[dsp_email]"', @response.body
    assert_match 'name="ht_registration[dsp_date]"', @response.body
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
        "dsp_name" => new_txt_val,
        "dsp_email" => new_email_val
      }
    }

    relookup = HTRegistration.find(@registration.id)

    assert_response :redirect
    assert_equal new_txt_val, relookup.jira_ticket
    assert_equal new_txt_val, relookup.auth_rep_name
    assert_equal new_email_val, relookup.auth_rep_email
    assert_equal new_txt_val, relookup.dsp_name
    assert_equal new_email_val, relookup.dsp_email
    assert_equal new_email_val, relookup.contact_info
  end

  test "fails update with bogus email" do
    bogus = "bogus_email"
    patch ht_registration_url @registration, params: {ht_registration: {"dsp_email" => bogus}}
    assert_response :success
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:alert]
    assert_not_equal bogus, HTRegistration.find(@registration.id).dsp_email
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
    assert_not_nil assigns(:finalize_url)
    assert_not_nil assigns(:email_body)
    assert_match /E-mail Preview/i, @response.body
    assert_select "input[value='SEND']"
  end

  test "e-mail preview is well-formed HTML" do
    check_w3c_errs do
      get preview_ht_registration_path @registration
    end
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
    @registration = create(:ht_registration)
  end

  def mail_registration(registration: @registration, params: {})
    sign_in!
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
end

class HTRegistrationFinishTest < ActionDispatch::IntegrationTest
  def setup
    @received_registration = create(:ht_registration, received: Time.now,
      ip_address: Faker::Internet.public_ip_v4_address,
      env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json)
    @mfa_inst = create(:ht_institution, shib_authncontext_class: "https://refeds.org/profile/mfa")
    @mfa_registration = create(:ht_registration, finished: Time.now, inst_id: @mfa_inst.inst_id,
      env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json)
  end

  test "finishing registration creates and displays a new user" do
    sign_in! username: ADMIN_USER
    post(finish_ht_registration_path(@received_registration))
    assert_response :redirect
    @received_registration.reload
    assert @received_registration.finished?
    assert_not_nil HTUser.find(@received_registration.dsp_email)
    follow_redirect!
    assert_equal "edit", @controller.action_name
  end

  test "finishing registration with MFA institution creates an MFA-enabled user" do
    sign_in! username: ADMIN_USER
    post(finish_ht_registration_path(@mfa_registration))
    user = HTUser.find(@mfa_registration.dsp_email)
    assert user.iprestrict.nil?
    assert user.mfa?
  end

  test "finishing registration a second time displays an error" do
    sign_in! username: ADMIN_USER
    post(finish_ht_registration_path(@received_registration))
    follow_redirect!
    post(finish_ht_registration_path(@received_registration))
    assert_not_empty flash[:alert]
  end
end
