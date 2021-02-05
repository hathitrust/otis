# frozen_string_literal: true

require 'test_helper'

class HTInstitutionPresenterTest < ActiveSupport::TestCase
  def presenter(inst)
    HTInstitutionPresenter.new(inst)
  end

  test 'us icon' do
    inst = build(:ht_institution, us: true)
    assert_match('glyphicon', presenter(inst).us_icon)
  end

  test 'no us icon' do
    inst = build(:ht_institution, us: false)
    assert_equal('', presenter(inst).us_icon)
  end

  test 'etas active' do
    inst = build(:ht_institution, emergency_status: '^(member)@default.invalid')
    assert_match('glyphicon', presenter(inst).etas_active_icon)
    assert_match('member', presenter(inst).etas_affiliations)
  end

  test 'etas inactive' do
    inst = build(:ht_institution, emergency_status: nil)
    assert_equal('', presenter(inst).etas_active_icon)
    assert_match('not enabled', presenter(inst).etas_affiliations)
  end

  test 'emergency contact link' do
    inst = build(:ht_institution, emergency_contact: 'somebody@default.invalid')
    assert_match('a href="mailto:somebody@default.invalid"', presenter(inst).emergency_contact_link)
  end

  test 'login link' do
    inst = build(:ht_institution, entityID: 'urn:something')
    assert_match('Shibboleth.sso/Login?entityID=urn:something', presenter(inst).login_test_link)
  end

  test 'mapped inst link' do
    inst = build(:ht_institution, mapto_inst_id: 'mapped')
    assert_match('ht_institutions/mapped', presenter(inst).mapped_inst_link)
  end

  test 'metadata link' do
    inst = build(:ht_institution, entityID: 'urn:something')
    assert_match('entity/urn:something', presenter(inst).metadata_link)
  end

  test 'mfa test absent' do
    inst = build(:ht_institution, shib_authncontext_class: nil)
    assert_nil(presenter(inst).mfa_test_link)
  end

  test 'mfa test link' do
    inst = build(:ht_institution, shib_authncontext_class: 'https://refeds.org/profile/mfa')
    assert_match('authnContextClassRef=https://refeds.org/profile/mfa', presenter(inst).mfa_test_link)
  end

  test 'grin link absent' do
    inst = build(:ht_institution, grin_instance: nil)
    assert_nil(presenter(inst).grin_link)
  end

  test 'grin link' do
    inst = build(:ht_institution, grin_instance: 'TEST')
    assert_match('/libraries/TEST', presenter(inst).grin_link)
  end
end

class HTInstitutionPresenterBadgeTest < ActiveSupport::TestCase
  def badge(inst)
    HTInstitutionPresenter.new(inst).badge
  end

  test 'disabled badge' do
    inst = build(:ht_institution, :disabled)
    assert_not_nil badge(inst)
    assert_match 'Disabled', badge(inst)
  end

  test 'enabled badge' do
    inst = build(:ht_institution, :enabled)
    assert_not_nil badge(inst)
    assert_match 'Enabled', badge(inst)
  end

  test 'private badge' do
    inst = build(:ht_institution, :private)
    assert_not_nil badge(inst)
    assert_match 'Private', badge(inst)
  end

  test 'social badge' do
    inst = build(:ht_institution, :social)
    assert_not_nil badge(inst)
    assert_match 'Social', badge(inst)
  end
end
