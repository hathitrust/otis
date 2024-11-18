# frozen_string_literal: true

require "test_helper"

class HTUserPresenterTest < ActiveSupport::TestCase
  test "class constants" do
    assert_not_nil HTUserPresenter::ALL_FIELDS
    assert_equal 15, HTUserPresenter::ALL_FIELDS.count
    assert_not_nil HTUserPresenter::INDEX_FIELDS
    assert_equal 8, HTUserPresenter::INDEX_FIELDS.count
  end

  test "field labels" do
    user = HTUserPresenter.new(create(:ht_user))
    HTUserPresenter::ALL_FIELDS.each do |field|
      assert_not_nil user.field_label(field)
    end
  end

  test "#badge with approval request displays a badge" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:ht_approval_request, userid: user.email)
    assert_match "span", user.field_value(:renewal_status)
  end

  test "#badge without approval request is blank" do
    user = HTUserPresenter.new(create(:ht_user))
    assert_match "", user.field_value(:renewal_status)
  end

  test "blank #mfa_icon" do
    user = HTUserPresenter.new(create(:ht_user, mfa: nil))
    assert_match "", user.field_value(:mfa)
  end

  test "non-blank #mfa_icon" do
    user = HTUserPresenter.new(create(:ht_user_mfa))
    assert_match "bi-lock", user.field_value(:mfa)
  end

  test "plain #mfa_label" do
    user = HTUserPresenter.new(create(:ht_user, mfa: nil))
    assert_equal "Multi-Factor", user.field_label(:mfa)
  end

  test "static field labels have no <label> markup" do
    user = HTUserPresenter.new(create(:ht_user_mfa), action: :show)
    HTUserPresenter::ALL_FIELDS.each do |field|
      refute_equal "LABEL", user.field_label(field)
    end
  end

  test "all labels for editable fields in form have a label tag" do
    user = HTUserPresenter.new(create(:ht_user_mfa), action: :edit)
    editable_fields = HTUserPresenter::ALL_FIELDS - HTUserPresenter::READ_ONLY_FIELDS
    editable_fields.each do |field|
      assert_equal "LABEL", user.field_label(field, form: FakeForm.new)
    end
  end

  test ":mfa value not available" do
    user = HTUserPresenter.new(create(:ht_user, mfa: nil))
    form = FakeForm.new
    assert_not_nil user.field_value(:mfa, form: form)
    assert_match "Unavailable", user.field_value(:mfa, form: form)
  end

  test ":mfa value has checkbox tag" do
    user = HTUserPresenter.new(create(:ht_user_mfa))
    assert_equal "CHECK BOX", user.field_value(:mfa, form: FakeForm.new)
  end

  test "select checkbox by default" do
    user = HTUserPresenter.new(create(:ht_user), action: :index)
    assert_match("checkbox", user.select_for_renewal_checkbox)
  end

  test "select checkbox if request is not renewed" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:ht_approval_request, renewed: nil, userid: user.email)
    assert_no_match("checkbox", user.select_for_renewal_checkbox)
  end

  test "select checkbox if user is renewed" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:ht_approval_request, :renewed, userid: user.email)
    assert_match("checkbox", user.select_for_renewal_checkbox)
  end

  test "email link has label by default" do
    user = HTUserPresenter.new(create(:ht_user), action: :index)
    assert_match "label", user.field_value(:email)
  end

  test "email link has no label if request is not renewed" do
    user = HTUserPresenter.new(create(:ht_user), action: :index)
    create(:ht_approval_request, renewed: nil, userid: user.email)
    refute_match "label", user.field_value(:email)
  end

  test "email link has label if request is renewed" do
    user = HTUserPresenter.new(create(:ht_user), action: :index)
    create(:ht_approval_request, :renewed, userid: user.email)
    assert_match "label", user.field_value(:email)
  end
end

class HTUserPresenterRoleDisplay < ActiveSupport::TestCase
  def setup
    @user = HTUserPresenter.new(build(:ht_user, role: "crms"))
    @user_unknown_role = HTUserPresenter.new(build(:ht_user, role: "blah"))
    @user_no_role = HTUserPresenter.new(build(:ht_user, role: nil))
  end

  test "User with a role has a natural-language name and description" do
    assert @user.role_name.length.positive?
    assert @user.role_description.length.positive?
  end

  test "User with bogus role lacks natural-language name and description" do
    assert_nil @user_unknown_role.role_name
    assert_nil @user_unknown_role.role_description
  end

  test "User with no role lacks natural-language name and description" do
    assert_nil @user_no_role.role_name
    assert_nil @user_no_role.role_description
  end
end
