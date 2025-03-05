# frozen_string_literal: true

require "test_helper"

class HTInstitutionPresenterTest < ActiveSupport::TestCase
  def presenter(inst, action: :show)
    HTInstitutionPresenter.new(inst, action: action)
  end

  test "#field_value :us for US institution" do
    inst = build(:ht_institution, us: true)
    assert_match "us_flag", presenter(inst).field_value(:us)
  end

  test "#field_value :us for non-US institution" do
    inst = build(:ht_institution, us: false)
    assert_no_match "flag-icon", presenter(inst).field_value(:us)
  end

  test "#field_value :emergency_status with ETAS enabled on index page" do
    inst = build(:ht_institution, emergency_status: "^(member)@default.invalid")
    assert_match "bg-success", presenter(inst, action: :index).field_value(:emergency_status)
  end

  test "#field_value :emergency_status with ETAS disabled on index page" do
    inst = build(:ht_institution, emergency_status: nil)
    assert_equal "", presenter(inst, action: :index).field_value(:emergency_status)
  end

  test "#field_value :emergency_status with ETAS enabled elsewhere" do
    inst = build(:ht_institution, emergency_status: "^(member)@default.invalid")
    assert_match "<code>", presenter(inst).field_value(:emergency_status)
  end

  test "#field_value :emergency_status with ETAS disabled elsewhere" do
    inst = build(:ht_institution, emergency_status: nil)
    assert_match "bg-danger", presenter(inst).field_value(:emergency_status)
  end

  test "#field_value :enabled disabled" do
    inst = build(:ht_institution, :disabled)
    assert_match "Disabled", presenter(inst).field_value(:enabled)
  end

  test "#field_value :enabled enabled" do
    inst = build(:ht_institution, :enabled)
    assert_match "Enabled", presenter(inst).field_value(:enabled)
  end

  test "#field_value :enabled private" do
    inst = build(:ht_institution, :private)
    assert_match "Private", presenter(inst).field_value(:enabled)
  end

  test "#field_value :enabled social" do
    inst = build(:ht_institution, :social)
    assert_match "Social", presenter(inst).field_value(:enabled)
  end

  test "#field_value :entityID" do
    inst = build(:ht_institution, entityID: "urn:something")
    assert_match "entity/urn:something", presenter(inst).field_value(:entityID)
  end

  test "#field_value :mapto_inst_id" do
    inst = build(:ht_institution, mapto_inst_id: "mapped")
    assert_match "ht_institutions/mapped", presenter(inst).field_value(:mapto_inst_id)
  end

  test "#login_test_url" do
    inst = build(:ht_institution, entityID: "urn:something")
    assert_match(%r{Shibboleth.sso/Login.*entityID=urn:something}, presenter(inst).login_test_url)
  end

  test "#mfa_test_url" do
    inst = build(:ht_institution, shib_authncontext_class: "https://refeds.org/profile/mfa")
    assert_match("authnContextClassRef=https://refeds.org/profile/mfa", presenter(inst).mfa_test_url)
  end

  test "#field_value :grin_instance present" do
    inst = build(:ht_institution, grin_instance: "TEST")
    assert_match "/libraries/TEST", presenter(inst).field_value(:grin_instance)
  end

  test "#field_value :grin_instance absent" do
    inst = build(:ht_institution, grin_instance: nil)
    assert_equal "", presenter(inst).field_value(:grin_instance)
  end

  test "#field_value :inst_id for new object is editable" do
    inst = build(:ht_institution)
    assert_equal "TEXT FIELD", presenter(inst, action: :new).field_value(:inst_id, form: FakeForm.new)
  end

  test "#field_value :inst_id for persisted object is not editable" do
    inst = create(:ht_institution)
    assert_equal inst.inst_id, presenter(inst, action: :edit).field_value(:inst_id, form: FakeForm.new)
  end
end

class HTInstitutionPresenterUserCountTest < ActiveSupport::TestCase
  def presenter(inst)
    HTInstitutionPresenter.new(inst)
  end

  test "user count" do
    inst = build(:ht_institution)
    create(:ht_user, ht_institution: inst)
    create(:ht_user, :expired, ht_institution: inst)
    assert_equal 2, presenter(inst).user_count
  end

  test "active user count" do
    inst = build(:ht_institution)
    create(:ht_user, ht_institution: inst)
    create(:ht_user, :expired, ht_institution: inst)
    assert_equal 1, presenter(inst).active_user_count
  end
end
