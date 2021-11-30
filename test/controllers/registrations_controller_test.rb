# frozen_string_literal: true

require "test_helper"

# All tests are run logged in as ADMIN_USER unless specified otherwise.
# I.e. add tests to ensure that roles who should not access can't access.
ADMIN_USER = "admin@default.invalid"

class RegistrationsControllerIndexTest < ActionDispatch::IntegrationTest
  def setup
    @registration = create(:registration)
    sign_in! username: ADMIN_USER
  end

  test "should get index" do
    get registrations_url
    assert_response :success
    assert_equal "index", @controller.action_name
    assert_not_nil assigns(:all_registrations)
    assert_match "Current Registrations", @response.body
  end

  test "index is well-formed HTML" do
    get registrations_url
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "as admin, shows link for new registration" do
    get registrations_url
    assert_match "registrations/new", @response.body
  end
end

class RegistrationsControllerShowTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @registration = create(:registration, inst_id: @inst.inst_id)
    sign_in! username: ADMIN_USER
  end

  test "should get show page" do
    get registration_url @registration
    assert_response :success
    assert_not_nil @registration
    assert_equal "show", @controller.action_name
  end

  test "show page is well-formed HTML" do
    get registration_url @registration
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "show page should include data from registration" do
    get registration_url @registration
    assert_match @registration.inst_id, @response.body
    assert_match @registration.jira_ticket, @response.body
    assert_match @registration.name, @response.body
    assert_match @registration.contact_info, @response.body
    assert_match @registration.auth_rep_name, @response.body
    assert_match @registration.auth_rep_email, @response.body
    assert_match @registration.auth_rep_date, @response.body
    assert_match @registration.dsp_name, @response.body
    assert_match @registration.dsp_email, @response.body
    assert_match @registration.dsp_date, @response.body
  end

  test "show page contains edit and delete buttons" do
    get registration_url @registration
    edit_btn = %r{<a.+?>Edit</a>}
    del_btn = %r{<a.+?>Delete Registration</a>}
    assert_match(edit_btn, @response.body)
    assert_match(del_btn, @response.body)
  end
end

class RegistrationsControllerCreateTest < ActionDispatch::IntegrationTest
  def setup
    sign_in! username: ADMIN_USER
  end

  test "new registration page has all the fields" do
    get new_registration_url
    assert_match 'name="registration[name]"', @response.body
    assert_select 'select[name="registration[inst_id]"]'
    assert_match 'name="registration[jira_ticket]"', @response.body
    assert_match 'name="registration[contact_info]"', @response.body
    assert_match 'name="registration[auth_rep_name]"', @response.body
    assert_match 'name="registration[auth_rep_email]"', @response.body
    assert_match 'name="registration[auth_rep_date]"', @response.body
    assert_match 'name="registration[dsp_name]"', @response.body
    assert_match 'name="registration[dsp_email]"', @response.body
    assert_match 'name="registration[dsp_date]"', @response.body
    assert_match 'name="registration[mfa_addendum]"', @response.body
  end

  test "can create" do
    params = FactoryBot.build(:registration).attributes.except(
      "created_at",
      "updated_at"
    ).symbolize_keys

    Registration.delete_all
    post registrations_url, params: {registration: params}
    assert_redirected_to registrations_url
    assert_equal 1, Registration.count

    # Shows up in log
    log = Registration.first.otis_logs.first
    assert_not_nil(log.data["params"])
    assert_equal(log.data["params"]["name"], params[:name])
    assert_equal(log.data["params"]["inst_id"], params[:inst_id])
    assert_equal(log.data["params"]["jira_ticket"], params[:jira_ticket])
    assert_equal(log.data["params"]["contact_info"], params[:contact_info])
    assert_equal(log.data["params"]["auth_rep_name"], params[:auth_rep_name])
    assert_equal(log.data["params"]["auth_rep_email"], params[:auth_rep_email])
    assert_equal(log.data["params"]["auth_rep_date"], params[:auth_rep_date])
    assert_equal(log.data["params"]["dsp_name"], params[:dsp_name])
    assert_equal(log.data["params"]["dsp_email"], params[:dsp_email])
    assert_equal(log.data["params"]["dsp_date"], params[:dsp_date])
    assert_equal(log.data["params"]["mfa_addendum"], params[:mfa_addendum])
  end
end

class RegistrationsControllerEditTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @registration = create(:registration, inst_id: @inst.inst_id)

    sign_in! username: ADMIN_USER
  end

  test "edit page is well-formed HTML" do
    get edit_registration_url @registration
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "form fields are present" do
    get edit_registration_url @registration
    assert_match 'name="registration[name]"', @response.body
    assert_select 'select[name="registration[inst_id]"]'
    assert_match 'name="registration[jira_ticket]"', @response.body
    assert_match 'name="registration[contact_info]"', @response.body
    assert_match 'name="registration[auth_rep_name]"', @response.body
    assert_match 'name="registration[auth_rep_email]"', @response.body
    assert_match 'name="registration[auth_rep_date]"', @response.body
    assert_match 'name="registration[dsp_name]"', @response.body
    assert_match 'name="registration[dsp_email]"', @response.body
    assert_match 'name="registration[dsp_date]"', @response.body
    assert_match 'name="registration[mfa_addendum]"', @response.body
  end

  test "can update fields" do
    new_txt_val = "updated by test"
    new_email_val = "upd@ted.biz"

    patch registration_url @registration, params: {
      registration: {
        "name" => new_txt_val,
        "jira_ticket" => new_txt_val,
        "contact_info" => new_txt_val,
        "auth_rep_name" => new_txt_val,
        "auth_rep_email" => new_email_val,
        "dsp_name" => new_txt_val,
        "dsp_email" => new_email_val
      }
    }

    relookup = Registration.find(@registration.id)

    assert_response :redirect
    assert_equal new_txt_val, relookup.name
    assert_equal new_txt_val, relookup.jira_ticket
    assert_equal new_txt_val, relookup.contact_info
    assert_equal new_txt_val, relookup.auth_rep_name
    assert_equal new_email_val, relookup.auth_rep_email
    assert_equal new_txt_val, relookup.dsp_name
    assert_equal new_email_val, relookup.dsp_email
  end

  test "fails update with bogus email" do
    bogus = "bogus_email"
    patch registration_url @registration, params: {registration: {"dsp_email" => bogus}}
    assert_response :success
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:alert]
    assert_not_equal bogus, Registration.find(@registration.id).dsp_email
  end
end

class RegistrationsControllerDeleteTest < ActionDispatch::IntegrationTest
  def setup
    @registration = create(:registration)
    sign_in! username: ADMIN_USER
  end

  test "delete destroys the registration" do
    reg_id = @registration.id
    delete registration_url @registration
    assert_response :redirect
    assert_equal "destroy", @controller.action_name
    assert_not_empty flash[:notice]
    assert_raises ActiveRecord::RecordNotFound do
      Registration.find reg_id
    end
  end
end
