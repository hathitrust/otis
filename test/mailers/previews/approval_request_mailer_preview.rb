# frozen_string_literal: true

class ApprovalRequestMailerPreview < ActionMailer::Preview
  def approval_request_email
    reqs = []
    HTApprovalRequest.all.sample(3).each do |req|
      reqs << req.dup
      reqs.last[:approver] = 'approver@example.com'
    end
    ApprovalRequestMailer.with(reqs: reqs).approval_request_email
  end
end
