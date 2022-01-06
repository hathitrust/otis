# frozen_string_literal: true

require "test_helper"

class HTRegistrationPresenterTest < ActiveSupport::TestCase
  def setup
    @reg = HTRegistrationPresenter.new(build(:ht_registration))
  end

  test "class constants" do
    assert_not_nil HTRegistrationPresenter::ALL_FIELDS
    assert_equal 11, HTRegistrationPresenter::ALL_FIELDS.count
    assert_not_nil HTRegistrationPresenter::INDEX_FIELDS
    assert_equal 7, HTRegistrationPresenter::INDEX_FIELDS.count
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
    # Localized value, can't make assumptions about content
    assert_match /mailto/, @reg.field_value(:auth_rep_email)
  end

  test "#field_value :dsp" do
    assert_match %r{#{@reg.dsp_name}.+mailto:#{@reg.dsp_email}.+<br/>.+}, @reg.field_value(:dsp)
  end

  test "#field_value :dsp_date" do
    # Localized value, can't make assumptions about content
    assert_not_nil @reg.field_value(:dsp_date)
  end

  test "#field_value :dsp_email displays as mailto link" do
    # Localized value, can't make assumptions about content
    assert_match /mailto/, @reg.field_value(:dsp_email)
  end

  test "#field_value :jira_ticket displays as link" do
    assert_not_nil @reg.field_value(:jira_ticket)
    assert_not_nil HTRegistrationPresenter::JIRA_BASE_URL
    assert_match "#{HTRegistrationPresenter::JIRA_BASE_URL}/#{@reg.jira_ticket}", @reg.field_value(:jira_ticket)
  end

  test "#field_value :inst_id displays as link" do
    assert_match %r{#{@reg.inst_id}.+>#{@reg.inst_id}<}, @reg.field_value(:inst_id)
  end

  test "#field_value :mfa_addendum displays as icon when set" do
    reg = HTRegistrationPresenter.new build(:ht_registration, mfa_addendum: true)
    assert_match %r{glyphicon-lock}, reg.field_value(:mfa_addendum)
  end

  test "#field_value :mfa_addendum blank when unset" do
    reg = HTRegistrationPresenter.new build(:ht_registration, mfa_addendum: false)
    assert_match "", reg.field_value(:mfa_addendum)
  end

  test "#field_value :name displays as link on index page" do
    reg = HTRegistrationPresenter.new build(:ht_registration), action: :index
    assert_match "/ht_registrations/#{reg.id}", reg.field_value(:name)
  end

  test "#field_value :name displays without link elsewhere" do
    reg = HTRegistrationPresenter.new build(:ht_registration), action: :show
    assert_no_match "/ht_registrations/#{reg.id}", reg.field_value(:name)
  end

  test "#field_value :inst_id edits as select menu" do
    assert_equal "SELECT", @reg.field_value(:inst_id, form: FakeForm.new)
  end

  test "#field_value :mfa_addendum edits as checkbox" do
    assert_equal "CHECK BOX", @reg.field_value(:mfa_addendum, form: FakeForm.new)
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
