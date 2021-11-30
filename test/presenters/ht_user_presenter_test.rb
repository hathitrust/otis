# frozen_string_literal: true

require "test_helper"

class HTUserPresenterTest < ActiveSupport::TestCase
  test "#badge with approval request displays a badge" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:approval_request, userid: user.email)
    assert_not_nil user.badge
    assert_match "span", user.badge
  end

  test "#badge without approval request is blank" do
    user = HTUserPresenter.new(create(:ht_user))
    assert_not_nil user.badge
    assert_match "", user.badge
  end

  test "blank #mfa_icon" do
    user = HTUserPresenter.new(create(:ht_user, mfa: nil))
    assert_not_nil user.mfa_icon
    assert_match "", user.mfa_icon
  end

  test "non-blank #mfa_icon" do
    user = HTUserPresenter.new(create(:ht_user_mfa))
    assert_not_nil user.mfa_icon
    assert_match "glyphicon", user.mfa_icon
  end

  test "plain #mfa_label" do
    user = HTUserPresenter.new(create(:ht_user, mfa: nil))
    assert_not_nil user.mfa_label
    assert_equal "Multi-Factor?:", user.mfa_label
  end

  test "label tag for #mfa_label" do
    user = HTUserPresenter.new(create(:ht_user_mfa))
    assert_not_nil user.mfa_label
    assert_match "label", user.mfa_label
  end

  test "#mfa_checkbox not available" do
    user = HTUserPresenter.new(create(:ht_user, mfa: nil))
    assert_not_nil user.mfa_checkbox
    assert_equal "Not Available", user.mfa_checkbox
  end

  test "checkbox tag for #mfa_checkbox" do
    user = HTUserPresenter.new(create(:ht_user_mfa))
    assert_not_nil user.mfa_checkbox
    assert_match "checkbox", user.mfa_checkbox
  end

  test "select checkbox by default" do
    user = HTUserPresenter.new(create(:ht_user))
    assert_match("checkbox", user.select_for_renewal_checkbox)
  end

  test "select checkbox if request is not renewed" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:approval_request, renewed: nil, userid: user.email)
    assert_no_match("checkbox", user.select_for_renewal_checkbox)
  end

  test "select checkbox if user is renewed" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:approval_request, :renewed, userid: user.email)
    assert_match("checkbox", user.select_for_renewal_checkbox)
  end

  test "email link has label by default" do
    user = HTUserPresenter.new(create(:ht_user))
    assert_match("label", user.email_link)
  end

  test "email link has no label if request is not renewed" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:approval_request, renewed: nil, userid: user.email)
    assert_no_match("label", user.email_link)
  end

  test "email link has label if request is renewed" do
    user = HTUserPresenter.new(create(:ht_user))
    create(:approval_request, :renewed, userid: user.email)
    assert_match("label", user.email_link)
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
