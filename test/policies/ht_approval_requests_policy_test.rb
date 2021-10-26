# frozen_string_literal: true

class HTApprovalRequestsPolicyTest < ActiveSupport::TestCase
  def setup
    @user = User.new("ht_approval_request_policy_test@default.invalid")
    @editable_req = create(:ht_approval_request)
    @uneditable_req = create(:ht_approval_request)
    agent = Checkpoint::Agent::Token.new("user", @user.id)
    admin_role = Checkpoint::Credential::Role.new(:admin)
    res_user = Checkpoint::Resource.new(@editable_req.ht_user)
    Services.checkpoint.grant!(agent, admin_role, res_user)
  end

  test "admin credential for HTUser permits editing its HTApprovalRequest" do
    assert HTApprovalRequestsPolicy.new.can?(:edit, @editable_req, @user)
  end

  test "admin credential for HTUser does not permit editing unrelated HTApprovalRequest" do
    refute HTApprovalRequestsPolicy.new.can?(:edit, @uneditable_req, @user)
  end
end
