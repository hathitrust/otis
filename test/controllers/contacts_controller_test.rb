# frozen_string_literal: true

require "test_helper"

class ContactsControllerIndexTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @contact = create(:contact, inst_id: @inst.inst_id)
  end

  test "should get index" do
    sign_in!
    get contacts_url
    assert_response :success
    assert_not_nil assigns(:contacts)
    assert_equal "index", @controller.action_name
    assert_match "Contacts", @response.body
    assert_match @contact.email, @response.body
  end

  test "index is well-formed HTML" do
    sign_in!
    get ht_institutions_url
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "contacts sorted by institution name" do
    inst1 = create(:ht_institution, name: "AAA University", enabled: true)
    inst2 = create(:ht_institution, name: "ZZZ University", enabled: true)
    create(:contact, inst_id: inst1.inst_id)
    create(:contact, inst_id: inst2.inst_id)
    sign_in!
    get ht_institutions_url

    assert_match(/AAA.*ZZZ/m, @response.body)
  end

  test "as admin, shows link for new contact" do
    sign_in! username: "admin@default.invalid"
    get contacts_url
    assert_match "contacts/new", @response.body
  end

  test "as non-admin, hides link for new contact" do
    sign_in! username: "staff@default.invalid"
    get contacts_url
    assert_no_match "contacts/new", @response.body
  end
end

class ContactsControllerSearchTest < ActionDispatch::IntegrationTest
  def setup
    @type1 = create(:contact_type)
    @type2 = create(:contact_type)
    @inst = create(:ht_institution)
    @contact1 = create(:contact, inst_id: @inst.inst_id, contact_type: @type1.id)
    @contact2 = create(:contact, inst_id: @inst.inst_id, contact_type: @type2.id)
  end

  test "should get index for specific contact type only" do
    sign_in!
    get contacts_url(contact_type: @type1.id)
    assert_response :success
    assert_not_nil assigns(:contacts)
    assert_equal "index", @controller.action_name
    assert_match "Contacts", @response.body
    assert_match @contact1.email, @response.body
    assert_no_match @contact2.email, @response.body
  end
end

class ContactsControllerCSVTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution, entityID: "http://example.com", inst_id: "I")
    @type1 = create(:contact_type, name: "T1")
    @type2 = create(:contact_type, name: "T2")
    @contact1 = Contact.new(inst_id: @inst.inst_id, contact_type: @type1.id, email: "a@b")
    @contact1.save!
    @contact2 = Contact.new(inst_id: @inst.inst_id, contact_type: @type2.id, email: "c@d")
    @contact2.save!
  end

  test "export list of all contacts as CSV" do
    sign_in!
    get contacts_url format: :csv
    assert_equal 3, @response.body.lines.count
    assert_match "#{@contact1.id},#{@inst.name},T1,a@b", @response.body
    assert_match "#{@contact2.id},#{@inst.name},T2,c@d", @response.body
  end

  test "export list of one contact type as CSV" do
    sign_in!
    get contacts_url format: :csv, contact_type: @type1.id
    assert_equal 2, @response.body.lines.count
    assert_match "#{@contact1.id},#{@inst.name},T1,a@b", @response.body
    assert_no_match "#{@contact2.id},#{@inst.name},T2,c@d", @response.body
  end
end

class ContactsControllerShowTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @type = create(:contact_type)
    @contact = create(:contact, ht_institution: @inst, contact_type: @type)
    sign_in!
  end

  test "should get show page" do
    get contact_url @contact
    assert_response :success
    assert_not_nil assigns(:contact)
    assert_equal "show", @controller.action_name
  end

  test "show page is well-formed HTML" do
    get contact_url @contact
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "shows contact institution name, type, email" do
    get contact_url @contact
    assert_match ERB::Util.html_escape(@contact.institution.name), @response.body
    assert_match ERB::Util.html_escape(@contact.contact_type.name), @response.body
    assert_match ERB::Util.html_escape(@contact.email), @response.body
  end
end

class ContactsControllerRolesTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @contact = create(:contact, ht_institution: @inst)
  end

  test "Staff user can see contacts index and show page" do
    sign_in! username: "staff@default.invalid"
    get contacts_url
    assert_response :success
    contact_url @contact
    assert_response :success
  end

  test "Institutions-only user can see contacts index and show page" do
    sign_in! username: "institution@default.invalid"
    get contacts_url
    assert_response :success
    contact_url @contact
    assert_response :success
  end

  test "Admin user can get edit page" do
    sign_in! username: "admin@default.invalid"
    get edit_contact_url @contact
    assert_response :success
    assert_equal "edit", @controller.action_name
  end

  test "Admin user can create new" do
    sign_in! username: "admin@default.invalid"
    get new_contact_url
    assert_response :success
    assert_equal "new", @controller.action_name
  end

  test "Staff user cannot create new" do
    sign_in! username: "staff@default.invalid"
    get new_contact_url
    assert_response :forbidden
  end

  test "Staff user cannot edit" do
    sign_in! username: "staff@default.invalid"
    get edit_contact_url @contact
    assert_response :forbidden
  end

  test "Staff user cannot update" do
    contact = create(:contact, inst_id: @inst.inst_id, email: "something@here.org")
    sign_in! username: "staff@default.invalid"
    patch contact_url @contact, params: {"contact" => {"email" => "nothing@there.org"}}
    assert_response :forbidden

    @contact.reload
    refute_equal Contact.find(contact.id).email, "nothing@there.org"
  end

  test "Staff user cannot create" do
    contact_params = attributes_for(:contact)
    sign_in! username: "staff@default.invalid"
    post contacts_url, params: {contact: contact_params}

    assert_response :forbidden
  end

  test "Contact user can get edit page" do
    sign_in! username: "contact@default.invalid"
    get edit_contact_url @contact
    assert_response :success
    assert_equal "edit", @controller.action_name
  end

  test "Contact user can create new" do
    sign_in! username: "contact@default.invalid"
    get new_contact_url
    assert_response :success
    assert_equal "new", @controller.action_name
  end
end

class ContactsControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "inst id and contact type editable for new contact" do
    get new_contact_url
    assert_select 'select[name="contact[inst_id]"]'
    assert_select 'select[name="contact[contact_type]"]'
  end

  test "can create" do
    contact_params = FactoryBot.build(:contact).attributes.except("created_at", "updated_at").symbolize_keys
    contact_id = contact_params[:id]
    post contacts_url, params: {contact: contact_params}

    assert_redirected_to contact_url(contact_id)

    assert_not_nil(Contact.find(contact_id))
  end

  test "logs create" do
    contact_params = FactoryBot.build(:contact).attributes.except("created_at", "updated_at").symbolize_keys
    contact_id = contact_params[:id]
    post contacts_url, params: {contact: contact_params}
    log = Contact.find(contact_id).otis_logs.first
    assert_equal(contact_id.to_s, log.data["params"]["id"])
    assert_not_nil(log.time)
  end
end

class ContactsControllerEditTest < ActionDispatch::IntegrationTest
  setup do
    @type = create(:contact_type)
    @inst = create(:ht_institution)
    @contact = create(:contact, ht_institution: @inst)
    sign_in! username: "admin@default.invalid"
  end

  test "edit page is well-formed HTML" do
    get edit_contact_url @contact
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "Institution and type menus present" do
    get edit_contact_url @contact
    assert_select 'select[name="contact[inst_id]"]'
    assert_select 'select[name="contact[contact_type]"]'
  end

  test "Can update institution" do
    other_inst = create(:ht_institution, inst_id: "other_inst")
    patch contact_url @contact, params: {contact: {"inst_id" => "other_inst"}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to contact_path(@contact)
    follow_redirect!

    assert_match ERB::Util.html_escape(other_inst.name), @response.body
    assert_equal other_inst.inst_id, Contact.find(@contact.id).inst_id
  end

  test "Can update contact type" do
    other_type = create(:contact_type)
    patch contact_url @contact, params: {contact: {"contact_type" => other_type.id}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to contact_path(@contact)
    follow_redirect!

    assert_match ERB::Util.html_escape(other_type.name), @response.body
    assert_equal other_type.id, Contact.find(@contact.id).contact_type.to_i
  end

  test "fails update with bogus email" do
    patch contact_url @contact, params: {contact: {"email" => "bogus_email"}}

    assert_response :success
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:alert]
  end
end

class ContactsControllerDeleteTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "delete destroys the contact" do
    @contact = create(:contact)
    contact_id = @contact.id
    delete contact_url @contact
    assert_response :redirect
    assert_equal "destroy", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to contacts_path
    follow_redirect!
    assert_raises ActiveRecord::RecordNotFound do
      Contact.find contact_id
    end
  end

  test "logs destroy" do
    @contact = create(:contact)
    contact_id = @contact.id
    delete contact_url @contact
    log = OtisLog.where(objid: contact_id, model: :Contact).order(:time).last
    assert_equal(contact_id.to_s, log.data["params"]["id"])
    assert_not_nil(log.time)
  end
end
