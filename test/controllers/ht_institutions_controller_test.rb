# frozen_string_literal: true

require 'test_helper'

class HTInstitutionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @institution1 = create(:ht_institution)
    @institution2 = create(:ht_institution)
  end

  test 'should get index' do
    sign_in!
    get ht_institutions_url
    assert_response :success
    assert_not_nil assigns(:institutions)
    assert_equal 'index', @controller.action_name
    assert_match 'Institutions', @response.body
    assert_match @institution1.inst_id, @response.body
    assert_match @institution2.inst_id, @response.body
  end

  test 'should get show page' do
    sign_in!
    get ht_institution_url @institution1
    assert_response :success
    assert_not_nil assigns(:institution)
    assert_equal 'show', @controller.action_name
    assert_match @institution1.inst_id, @response.body
    assert_match @institution1.name, @response.body
  end

  test 'enabled institutions separated from disabled ones' do
    enabled  = create(:ht_institution, enabled: true)
    disabled = create(:ht_institution, enabled: false)

    sign_in!
    get ht_institutions_url

    assert_match(/Active Institutions.*#{enabled.inst_id}.*Inactive Institutions.*#{disabled.inst_id}/m, @response.body)
  end

  test 'institutions sorted by name' do
    create(:ht_institution, name: 'AAA University', enabled: true)
    create(:ht_institution, name: 'ZZZ University', enabled: true)

    sign_in!
    get ht_institutions_url

    assert_match(/AAA.*ZZZ/m, @response.body)
  end
end
