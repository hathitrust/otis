# frozen_string_literal: true

require 'test_helper'

class HTInstitutionsIndexTest < ActionDispatch::IntegrationTest
  def setup
    @institution1 = create(:ht_institution)
    @institution2 = create(:ht_institution)
  end

  test 'should get index' do
    sign_in!
    get ht_institutions_url
    assert_response :success
    assert_not_nil assigns(:enabled_institutions)
    assert_equal 'index', @controller.action_name
    assert_match 'Institutions', @response.body
    assert_match @institution1.inst_id, @response.body
    assert_match @institution2.inst_id, @response.body
  end

  test 'enabled institutions separated from disabled ones' do
    enabled  = create(:ht_institution, enabled: true)
    disabled = create(:ht_institution, enabled: false)

    sign_in!
    get ht_institutions_url

    assert_match(/Enabled Institutions.*#{enabled.inst_id}.*Other Institutions.*#{disabled.inst_id}/m, @response.body)
  end

  test 'institutions sorted by name' do
    create(:ht_institution, name: 'AAA University', enabled: true)
    create(:ht_institution, name: 'ZZZ University', enabled: true)

    sign_in!
    get ht_institutions_url

    assert_match(/AAA.*ZZZ/m, @response.body)
  end
end

class HTInstitutionsShowTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @mfa_inst = create(:ht_institution, name: 'MFA University', enabled: true, 
           shib_authncontext_class: 'https://refeds.org/profile/mfa')
  end

  test 'should get show page' do
    sign_in!
    get ht_institution_url @inst
    assert_response :success
    assert_not_nil assigns(:institution)
    assert_equal 'show', @controller.action_name
  end

  test 'shows institution name and id' do
    sign_in!
    get ht_institution_url @inst
    assert_match @inst.inst_id, @response.body
    assert_match ERB::Util.html_escape(@inst.name), @response.body
  end

  test 'Shows whoami link' do
    sign_in!
    get ht_institution_url @inst
    assert_match(%r{/cgi/whoami}m, @response.body)
  end

  test 'With MFA auth context, shows whoami link with step-up MFA' do
    sign_in!
    get ht_institution_url @mfa_inst
    assert_match(%r{authnContextClassRef=https://refeds.org/profile/mfa}m, @response.body)
  end
end

class HTInstitutionsControllerRolesTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution, inst_id: 'whatever')
  end

  test 'Staff user can see ht_institutions index and show page' do
    sign_in! username: 'staff@default.invalid'
    get ht_institutions_url
    assert_response :success
    ht_institution_url @inst
    assert_response :success
  end

  test 'Institutions-only user can see ht_institutions index and show page' do
    sign_in! username: 'institution@default.invalid'
    get ht_institutions_url
    assert_response :success
    ht_institution_url @inst
    assert_response :success
  end

  test 'Admin user can get edit page' do
    sign_in! username: 'admin@default.invalid'
    get edit_ht_institution_url @inst
    assert_response :success
    assert_equal 'edit', @controller.action_name
  end

  test 'Staff user cannot edit' do
    sign_in! username: 'staff@default.invalid'
    get edit_ht_institution_url @inst
    assert_response :forbidden
  end

  test 'Staff user cannot update' do
    inst = create(:ht_institution, emergency_status: nil)
    sign_in! username: 'staff@default.invalid'
    patch ht_institution_url inst, params: {'ht_institution' => {'emergency_status' => 'anything'}}
    assert_response :forbidden

    inst.reload
    assert_nil HTInstitution.find(inst.inst_id).emergency_status
  end

end

class HTInstitutionsControllerEditTest < ActionDispatch::IntegrationTest

  test 'Editable fields present' do
    EDITABLE_FIELDS = %w[emergency_status emergency_contact].freeze
    inst = create(:ht_institution)
    sign_in! username: 'admin@default.invalid'
    get edit_ht_institution_url(inst)
    EDITABLE_FIELDS.each do |ef|
      assert_match(/name="ht_institution\[#{ef}\]"/, @response.body)
    end
  end

  test 'Can update emergency status' do
    new_status = '^(member)@university.invalid'
    inst = create(:ht_institution, emergency_status: nil)
    sign_in! username: 'admin@default.invalid'
    patch ht_institution_url inst, params: {'ht_institution' => {'emergency_status' => new_status}}

    assert_response :redirect
    assert_equal 'update', @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_institution_path(inst)
    follow_redirect!

    assert_match new_status, @response.body
    assert_equal new_status, HTInstitution.find(inst.inst_id).emergency_status
  end

  test 'Blank emergency status sets null' do
    inst = create(:ht_institution, emergency_status: '^(member)@university.invalid')
    sign_in! username: 'admin@default.invalid'
    patch ht_institution_url inst, params: {'ht_institution' => {'emergency_status' => ''}}

    assert_response :redirect
    assert_equal 'update', @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_institution_path(inst)
    follow_redirect!

    assert_nil HTInstitution.find(inst.inst_id).emergency_status
  end

end
