# frozen_string_literal: true

module ApplicationHelper
  # As a substitute for end-to-end logging, if there is no request in for
  # the user's designated approver, we create one with the approver set to
  # the HathiTrust staff member.
  def add_or_update_renewal(email)
    u = HTUser.where(email: email).first
    raise StandardError, "Unknown user '#{email}'" if u.nil?

    req = HTApprovalRequest.not_renewed_for_user(u.email).first
    req = HTApprovalRequest.new(approver: current_user.id, userid: u.email) if req.nil?
    req.renewed = Time.zone.now
    req.save!
    u.renew!
  end
end
