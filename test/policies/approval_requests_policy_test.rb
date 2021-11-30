# frozen_string_literal: true

class ApprovalRequestsPolicyTest < ActiveSupport::TestCase
  def setup
    @user = User.new("approval_request_policy_test@default.invalid")
    @editable_req = create(:approval_request)
    @uneditable_req = create(:approval_request)
    agent = Checkpoint::Agent::Token.new("user", @user.id)
    admin_role = Checkpoint::Credential::Role.new(:admin)
    res_user = Checkpoint::Resource.new(@editable_req.ht_user)
    Services.checkpoint.grant!(agent, admin_role, res_user)
  end

  test "admin credential for HTUser permits editing its ApprovalRequest" do
    assert ApprovalRequestsPolicy.new.can?(:edit, @editable_req, @user)
  end

  test "admin credential for HTUser does not permit editing unrelated ApprovalRequest" do
    refute ApprovalRequestsPolicy.new.can?(:edit, @uneditable_req, @user)
  end
end
