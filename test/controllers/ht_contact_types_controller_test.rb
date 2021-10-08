# frozen_string_literal: true

require "test_helper"

class HTContactTypesIndexTest < ActionDispatch::IntegrationTest
  def setup
    @type1 = create(:ht_contact_type, name: "AAA Type")
    @type2 = create(:ht_contact_type, name: "ZZZ Type")
  end

  test "should get index" do
    sign_in!
    get ht_contact_types_url
    assert_response :success
    assert_not_nil assigns(:contact_types)
    assert_equal "index", @controller.action_name
    assert_match "Contact Types", @response.body
    assert_match @type1.name, @response.body
    assert_match @type2.name, @response.body
  end

  test "index is well-formed HTML" do
    sign_in!
    get ht_contact_types_url
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "contact types sorted by name" do
    sign_in!
    get ht_contact_types_url

    assert_match(/AAA.*ZZZ/m, @response.body)
  end

  test "as admin, shows link for new contact type" do
    sign_in! username: "admin@default.invalid"
    get ht_contact_types_url
    assert_match "contact_types/new", @response.body
  end
end

class HTContactTypesShowTest < ActionDispatch::IntegrationTest
  def setup
    @type = create(:ht_contact_type, name: "Some Type")
    sign_in!
  end

  test "should get show page" do
    get ht_contact_type_url @type
    assert_response :success
    assert_not_nil assigns(:contact_type)
    assert_equal "show", @controller.action_name
  end

  test "show page is well-formed HTML" do
    get ht_contact_type_url @type
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "shows id, name, and description" do
    get ht_contact_type_url @type
    assert_match ERB::Util.html_escape(@type.id), @response.body
    assert_match ERB::Util.html_escape(@type.name), @response.body
    assert_match ERB::Util.html_escape(@type.description), @response.body
  end
end

class HTContactTypesControllerRolesTest < ActionDispatch::IntegrationTest
  def setup
    @type = create(:ht_contact_type, name: "Some Type")
  end

  test "Staff user can see ht_contact_types index and show page" do
    sign_in! username: "staff@default.invalid"
    get ht_contact_types_url
    assert_response :success
    ht_contact_types_url @type
    assert_response :success
  end

  test "Institutions-only user can see ht_contact_types index and show page" do
    sign_in! username: "institution@default.invalid"
    get ht_contact_types_url
    assert_response :success
    ht_contact_types_url @type
    assert_response :success
  end

  test "Admin user can get edit page" do
    sign_in! username: "admin@default.invalid"
    get edit_ht_contact_type_url @type
    assert_response :success
    assert_equal "edit", @controller.action_name
  end

  test "Admin user can create new" do
    sign_in! username: "admin@default.invalid"
    get new_ht_contact_type_url
    assert_response :success
    assert_equal "new", @controller.action_name
  end

  test "Staff user cannot create new" do
    sign_in! username: "staff@default.invalid"
    get new_ht_contact_type_url
    assert_response :forbidden
  end

  test "Staff user cannot edit" do
    sign_in! username: "staff@default.invalid"
    get edit_ht_contact_type_url @type
    assert_response :forbidden
  end

  test "Staff user cannot update" do
    type = create(:ht_contact_type, name: "Something")
    sign_in! username: "staff@default.invalid"
    patch ht_contact_type_url type, params: {ht_contact_type: {"name" => "Nothing"}}
    assert_response :forbidden

    type.reload
    refute_equal "Nothing", HTContactType.find(type.id).name
  end

  test "Staff user cannot create" do
    contact_type_params = attributes_for(:ht_contact_type)
    sign_in! username: "staff@default.invalid"
    post ht_contact_types_url, params: {ht_contact_type: contact_type_params}

    assert_response :forbidden
  end
end

class HTContactTypesControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "name and description editable for new contact type" do
    get new_ht_contact_type_url
    assert_select 'input[name="ht_contact_type[name]"]'
    assert_select 'textarea[name="ht_contact_type[description]"]'
  end

  test "Can create" do
    type_params = attributes_for(:ht_contact_type)
    type_id = type_params[:id]
    post ht_contact_types_url, params: {ht_contact_type: type_params}
    assert_redirected_to ht_contact_type_url(type_id)
    assert_not_nil(HTContactType.find(type_id))
  end

  test "logs create" do
    type_params = attributes_for(:ht_contact_type)
    type_id = type_params[:id]
    post ht_contact_types_url, params: {ht_contact_type: type_params}
    log = HTContactType.find(type_id).ht_logs.first
    assert_equal(type_id.to_s, log.data["params"]["id"])
    assert_not_nil(log.time)
  end
end

class HTContactTypesControllerEditTest < ActionDispatch::IntegrationTest
  setup do
    @type = create(:ht_contact_type)
    sign_in! username: "admin@default.invalid"
  end

  test "edit page is well-formed HTML" do
    get edit_ht_contact_type_url @type
    assert_equal 0, w3c_errs(@response.body).length
  end

  test "Editable name and description fields present" do
    get edit_ht_contact_type_url(@type)
    editable_fields = %w[name description]
    editable_fields.each do |field|
      assert_match(/name="ht_contact_type\[#{field}\]"/, @response.body)
    end
  end

  test "Can update name" do
    name = "BLAH"
    patch ht_contact_type_url @type, params: {ht_contact_type: {"name" => name}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_contact_type_path(@type)
    follow_redirect!

    assert_match name, @response.body
    assert_equal name, HTContactType.find(@type.id).name
  end

  test "Can update description" do
    desc = "Blah blah blah"
    patch ht_contact_type_url @type, params: {ht_contact_type: {"description" => desc}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_contact_type_path(@type)
    follow_redirect!

    assert_match desc, @response.body
    assert_equal desc, HTContactType.find(@type.id).description
  end

  test "fails update with blank field" do
    patch ht_contact_type_url @type, params: {ht_contact_type: {"name" => ""}}

    assert_response :success
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:alert]
  end
end

class HTContactTypesControllerDeleteTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "delete destroys the contact type" do
    @type = create(:ht_contact_type)
    type_id = @type.id
    delete ht_contact_type_url @type
    assert_response :redirect
    assert_equal "destroy", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_contact_types_path
    follow_redirect!
    assert_raises ActiveRecord::RecordNotFound do
      HTContactType.find type_id
    end
  end

  test "destroy fails when type is in use by contact" do
    @type = create(:ht_contact_type)
    type_id = @type.id
    @contact = create(:ht_contact, contact_type: @type.id)
    delete ht_contact_type_url @type
    assert_response :success
    assert_equal "destroy", @controller.action_name
    assert_not_empty flash[:alert]
    assert_not_nil HTContactType.find type_id
  end

  test "logs destroy" do
    @type = create(:ht_contact_type)
    type_id = @type.id
    delete ht_contact_type_url @type
    log = HTLog.where(objid: type_id, model: :HTContactType).order(:time).last
    assert_equal(type_id.to_s, log.data["params"]["id"])
    assert_not_nil(log.time)
  end
end
