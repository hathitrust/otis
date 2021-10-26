# frozen_string_literal: true

class ApplicationPolicyTest < ActiveSupport::TestCase
  def setup
    @user = User.new("application_policy_test@default.invalid")
    @ht_user = create(:ht_user)
    agent = Checkpoint::Agent::Token.new("user", @user.id)
    view_role = Checkpoint::Credential::Role.new(:view)
    res_users = Checkpoint::Resource::AllOfType.new(:ht_user)
    Services.checkpoint.grant!(agent, view_role, res_users)
  end

  test "view credential permits ht_users index" do
    assert ApplicationPolicy.new.can?(:index, HTUser, @user)
  end

  test "view credential permits showing a particular HTUser" do
    assert ApplicationPolicy.new.can?(:show, @ht_user, @user)
  end

  test "view credential forbids deleting a particular HTUser" do
    refute ApplicationPolicy.new.can?(:delete, @ht_user, @user)
  end
end
