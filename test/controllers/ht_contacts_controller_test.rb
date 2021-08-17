# frozen_string_literal: true

require "test_helper"
require "w3c_validators"

class HTContactsControllerIndexTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @contact = create(:ht_contact, inst_id: @inst.inst_id)
  end

  test "should get index" do
    sign_in!
    get ht_contacts_url
    assert_response :success
    assert_not_nil assigns(:contacts)
    assert_equal "index", @controller.action_name
    assert_match "Contacts", @response.body
    assert_match @contact.email, @response.body
  end

  test "index is well-formed HTML" do
    sign_in!
    get ht_institutions_url
    validator = W3CValidators::NuValidator.new
    w3c_errs = validator.validate_text(@response.body).errors
    sleep 1
    assert_equal 0, w3c_errs.length, w3c_errs.join("\n")
  end

  test "contacts sorted by institution name" do
    inst1 = create(:ht_institution, name: "AAA University", enabled: true)
    inst2 = create(:ht_institution, name: "ZZZ University", enabled: true)
    create(:ht_contact, inst_id: inst1.inst_id)
    create(:ht_contact, inst_id: inst2.inst_id)
    sign_in!
    get ht_institutions_url

    assert_match(/AAA.*ZZZ/m, @response.body)
  end

  test "as admin, shows link for new contact" do
    sign_in! username: "admin@default.invalid"
    get ht_contacts_url
    assert_match "contacts/new", @response.body
  end

  test "as non-admin, shows link for new contact" do
    sign_in! username: "staff@default.invalid"
    get ht_contacts_url
    assert_no_match "contacts/new", @response.body
  end
end

class HTContactsControllerShowTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @type = create(:ht_contact_type)
    @contact = create(:ht_contact, ht_institution: @inst, ht_contact_type: @type)
    sign_in!
  end

  test "should get show page" do
    get ht_contact_url @contact
    assert_response :success
    assert_not_nil assigns(:contact)
    assert_equal "show", @controller.action_name
  end

  test "show page is well-formed HTML" do
    get ht_contact_url @contact
    validator = W3CValidators::NuValidator.new
    w3c_errs = validator.validate_text(@response.body).errors
    sleep 1
    assert_equal 0, w3c_errs.length, w3c_errs.join("\n")
  end

  test "shows contact institution name, type, email" do
    get ht_contact_url @contact
    assert_match ERB::Util.html_escape(@contact.institution.name), @response.body
    assert_match ERB::Util.html_escape(@contact.ht_contact_type.name), @response.body
    assert_match ERB::Util.html_escape(@contact.email), @response.body
  end
end

class HTContactsControllerRolesTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @contact = create(:ht_contact, ht_institution: @inst)
  end

  test "Staff user can see ht_contacts index and show page" do
    sign_in! username: "staff@default.invalid"
    get ht_contacts_url
    assert_response :success
    ht_contact_url @contact
    assert_response :success
  end

  test "Institutions-only user can see ht_contacts index and show page" do
    sign_in! username: "institution@default.invalid"
    get ht_contacts_url
    assert_response :success
    ht_contact_url @contact
    assert_response :success
  end

  test "Admin user can get edit page" do
    sign_in! username: "admin@default.invalid"
    get edit_ht_contact_url @contact
    assert_response :success
    assert_equal "edit", @controller.action_name
  end

  test "Admin user can create new" do
    sign_in! username: "admin@default.invalid"
    get new_ht_contact_url
    assert_response :success
    assert_equal "new", @controller.action_name
  end

  test "Staff user cannot create new" do
    sign_in! username: "staff@default.invalid"
    get new_ht_contact_url
    assert_response :forbidden
  end

  test "Staff user cannot edit" do
    sign_in! username: "staff@default.invalid"
    get edit_ht_contact_url @contact
    assert_response :forbidden
  end

  test "Staff user cannot update" do
    contact = create(:ht_contact, inst_id: @inst.inst_id, email: "something@here.org")
    sign_in! username: "staff@default.invalid"
    patch ht_contact_url @contact, params: {"ht_contact" => {"email" => "nothing@there.org"}}
    assert_response :forbidden

    @contact.reload
    refute_equal HTContact.find(contact.id).email, "nothing@there.org"
  end

  test "Staff user cannot create" do
    contact_params = attributes_for(:ht_contact)
    sign_in! username: "staff@default.invalid"
    post ht_contacts_url, params: {ht_contact: contact_params}

    assert_response :forbidden
  end

  test "Contact user can get edit page" do
    sign_in! username: "contact@default.invalid"
    get edit_ht_contact_url @contact
    assert_response :success
    assert_equal "edit", @controller.action_name
  end

  test "Contact user can create new" do
    sign_in! username: "contact@default.invalid"
    get new_ht_contact_url
    assert_response :success
    assert_equal "new", @controller.action_name
  end
end

class HTContactsControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "inst id and contact type editable for new contact" do
    get new_ht_contact_url
    assert_select 'select[name="ht_contact[inst_id]"]'
    assert_select 'select[name="ht_contact[contact_type]"]'
  end

  test "can create" do
    contact_params = FactoryBot.build(:ht_contact).attributes.except("created_at", "updated_at").symbolize_keys
    contact_id = contact_params[:id]
    post ht_contacts_url, params: {ht_contact: contact_params}

    assert_redirected_to ht_contact_url(contact_id)

    assert_not_nil(HTContact.find(contact_id))
  end

  test "logs create" do
    contact_params = FactoryBot.build(:ht_contact).attributes.except("created_at", "updated_at").symbolize_keys
    contact_id = contact_params[:id]
    post ht_contacts_url, params: {ht_contact: contact_params}
    log = HTInstitution.find(contact_params[:inst_id]).ht_institution_log.first
    assert_equal(contact_id.to_s, log.data["params"]["id"])
    assert_not_nil(log.time)
  end
end

class HTContactsControllerEditTest < ActionDispatch::IntegrationTest
  setup do
    @type = create(:ht_contact_type)
    @inst = create(:ht_institution)
    @contact = create(:ht_contact, ht_institution: @inst)
    sign_in! username: "admin@default.invalid"
  end

  test "edit page is well-formed HTML" do
    get edit_ht_contact_url @contact
    validator = W3CValidators::NuValidator.new
    w3c_errs = validator.validate_text(@response.body).errors
    sleep 1
    assert_equal 0, w3c_errs.length, w3c_errs.join("\n")
  end

  test "Institution and type menus present" do
    get edit_ht_contact_url @contact
    assert_select 'select[name="ht_contact[inst_id]"]'
    assert_select 'select[name="ht_contact[contact_type]"]'
  end

  test "Can update institution" do
    other_inst = create(:ht_institution, inst_id: "other_inst")
    patch ht_contact_url @contact, params: {ht_contact: {"inst_id" => "other_inst"}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_contact_path(@contact)
    follow_redirect!

    assert_match other_inst.name, @response.body
    assert_equal other_inst.inst_id, HTContact.find(@contact.id).inst_id
  end

  test "Can update contact type" do
    other_type = create(:ht_contact_type)
    patch ht_contact_url @contact, params: {ht_contact: {"contact_type" => other_type.id}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_contact_path(@contact)
    follow_redirect!

    assert_match other_type.name, @response.body
    assert_equal other_type.id, HTContact.find(@contact.id).contact_type.to_i
  end

  test "fails update with bogus email" do
    patch ht_contact_url @contact, params: {ht_contact: {"email" => "bogus_email"}}

    assert_response :success
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:alert]
  end
end

class HTContactsControllerDeleteTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "delete destroys the contact" do
    @contact = create(:ht_contact)
    contact_id = @contact.id
    delete ht_contact_url @contact
    assert_response :redirect
    assert_equal "destroy", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_contacts_path
    follow_redirect!
    assert_raises ActiveRecord::RecordNotFound do
      HTContact.find contact_id
    end
  end
end
