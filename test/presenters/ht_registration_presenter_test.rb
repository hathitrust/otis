# frozen_string_literal: true

require "test_helper"

class HTRegistrationPresenterTest < ActiveSupport::TestCase
  def setup
    @reg = HTRegistrationPresenter.new(build(:ht_registration))
  end

  test "class constants" do
    assert_not_nil HTRegistrationPresenter::ALL_FIELDS
    assert_not_nil HTRegistrationPresenter::INDEX_FIELDS
  end

  test "field labels" do
    HTRegistrationPresenter::ALL_FIELDS.each do |field|
      assert_not_nil @reg.field_label(field)
    end
  end

  test "#field_value :auth_rep" do
    assert_match %r{#{@reg.auth_rep_name}.+mailto:#{@reg.auth_rep_email}.+<br/>.+},
      @reg.field_value(:auth_rep)
  end

  test "#field_value :auth_rep_date" do
    # Localized value, can't make assumptions about content
    assert_not_nil @reg.field_value(:auth_rep_date)
  end

  test "#field_value :auth_rep_email displays as mailto link" do
    assert_match /mailto/, @reg.field_value(:auth_rep_email)
  end

  test "#field_value :applicant displays with a link" do
    assert_match /href/, @reg.field_value(:applicant)
  end

  test "#field_value :applicant_date" do
    # Localized value, can't make assumptions about content
    assert_not_nil @reg.field_value(:applicant_date)
  end

  test "#field_value :applicant_email displays as mailto link" do
    assert_match /mailto/, @reg.field_value(:applicant_email)
  end

  test "#field_value :jira_ticket displays as link" do
    assert_not_nil @reg.field_value(:jira_ticket)
    assert_not_nil HTRegistrationPresenter::JIRA_BASE_URL
    assert_match "href", @reg.field_value(:jira_ticket)
    assert_match HTRegistrationPresenter::JIRA_BASE_URL, @reg.field_value(:jira_ticket)
    assert_match @reg.jira_ticket, @reg.field_value(:jira_ticket)
  end

  test "#field_value :inst_id displays as link" do
    assert_match "href", @reg.field_value(:inst_id)
  end

  test "#field_value :mfa_addendum displays as icon when set" do
    reg = HTRegistrationPresenter.new build(:ht_registration, mfa_addendum: true)
    assert_match %r{glyphicon-lock}, reg.field_value(:mfa_addendum)
  end

  test "#field_value :mfa_addendum blank when unset" do
    reg = HTRegistrationPresenter.new build(:ht_registration, mfa_addendum: false)
    assert_match "", reg.field_value(:mfa_addendum)
  end

  test "#field_value :inst_id edits as select menu" do
    assert_equal "SELECT", @reg.field_value(:inst_id, form: FakeForm.new)
  end

  test "#field_value :mfa_addendum edits as checkbox" do
    assert_equal "CHECK BOX", @reg.field_value(:mfa_addendum, form: FakeForm.new)
  end

  test "#field_value :role edits as select menu" do
    assert_equal "SELECT", @reg.field_value(:role, form: FakeForm.new)
  end

  test "#cancel_path for new object goes to index" do
    assert_not_nil @reg.cancel_path
    assert_no_match "/ht_registrations/#{@reg.id}", @reg.cancel_path
  end

  test "#cancel_path for persisted object goes to object" do
    reg = HTRegistrationPresenter.new(create(:ht_registration))
    assert_match "/ht_registrations/#{reg.id}", reg.cancel_path
  end
end

class HTRegistrationPresenterENVTest < ActiveSupport::TestCase
  def setup
    @inst = create(:ht_institution, inst_id: "test",
      allowed_affiliations: "faculty@default.invalid;staff@default.invalid")
    @nypl = create(:ht_institution, inst_id: "nypl")
    @ok = I18n.t("activerecord.attributes.ht_registration.detail.ok")
    @mismatch = I18n.t("activerecord.attributes.ht_registration.detail.mismatch")
    @questionable = I18n.t("activerecord.attributes.ht_registration.detail.questionable")
  end

  test "HTTP_X_SHIB_EDUPERSONPRINCIPALNAME match" do
    reg = HTRegistrationPresenter.new build(:ht_registration)
    reg.env = {"HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => reg.applicant_email}.to_json
    assert_match @ok, reg.field_value(:detail_edu_person_principal_name)
  end

  test "HTTP_X_SHIB_EDUPERSONPRINCIPALNAME mismatch" do
    reg = HTRegistrationPresenter.new build(:ht_registration)
    reg.env = {"HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => "nobody@default.invalid"}.to_json
    assert_match @questionable, reg.field_value(:detail_edu_person_principal_name)
  end

  test "HTTP_X_SHIB_MAIL match" do
    reg = HTRegistrationPresenter.new build(:ht_registration)
    reg.env = {"HTTP_X_SHIB_MAIL" => reg.applicant_email}.to_json
    assert_match @ok, reg.field_value(:detail_email)
  end

  test "HTTP_X_SHIB_MAIL mismatch" do
    reg = HTRegistrationPresenter.new build(:ht_registration)
    reg.env = {"HTTP_X_SHIB_MAIL" => "nobody@default.invalid"}.to_json
    assert_match @questionable, reg.field_value(:detail_email)
  end

  test "HTTP_X_SHIB_IDENTITY_PROVIDER match" do
    reg = HTRegistrationPresenter.new build(:ht_registration, inst_id: @inst.inst_id)
    reg.env = {"HTTP_X_SHIB_IDENTITY_PROVIDER" => @inst.entityID}.to_json
    assert_match @ok, reg.field_value(:detail_identity_provider)
  end

  test "HTTP_X_SHIB_IDENTITY_PROVIDER mismatch" do
    reg = HTRegistrationPresenter.new build(:ht_registration, inst_id: @inst.inst_id)
    reg.env = {"HTTP_X_SHIB_IDENTITY_PROVIDER" => "http://default.invalid"}.to_json
    assert_match @mismatch, reg.field_value(:detail_identity_provider)
  end

  test "HTTP_X_SHIB_IDENTITY_PROVIDER NYPL" do
    reg = HTRegistrationPresenter.new build(:ht_registration, inst_id: @nypl.inst_id)
    reg.env = {"HTTP_X_SHIB_IDENTITY_PROVIDER" => "http://default.nypl.invalid"}.to_json
    assert_no_match @ok, reg.field_value(:detail_identity_provider)
    assert_no_match @mismatch, reg.field_value(:detail_identity_provider)
  end

  test "HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION match" do
    reg = HTRegistrationPresenter.new build(:ht_registration, inst_id: @inst.inst_id)
    reg.env = {"HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION" => "something@default.invalid;staff@default.invalid"}.to_json
    assert_match @ok, reg.field_value(:detail_scoped_affiliation)
  end

  test "HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION mismatch with invalid affiliations" do
    reg = HTRegistrationPresenter.new build(:ht_registration, inst_id: @inst.inst_id)
    reg.env = {"HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION" => "something@default.invalid"}.to_json
    assert_match @mismatch, reg.field_value(:detail_scoped_affiliation)
  end

  test "HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION mismatch with mismatched affiliations" do
    reg = HTRegistrationPresenter.new build(:ht_registration, inst_id: @inst.inst_id)
    reg.env = {"HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION" => "employee@default.invalid"}.to_json
    assert_match @mismatch, reg.field_value(:detail_scoped_affiliation)
  end

  test "HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION NYPL" do
    reg = HTRegistrationPresenter.new build(:ht_registration, inst_id: @nypl.inst_id)
    reg.env = {"HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION" => "something@default.nypl.invalid;staff@default.nypl.invalid"}.to_json
    assert_no_match @ok, reg.field_value(:detail_scoped_affiliation)
    assert_no_match @mismatch, reg.field_value(:detail_scoped_affiliation)
  end
end
