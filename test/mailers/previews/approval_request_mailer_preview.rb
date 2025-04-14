# frozen_string_literal: true

class ApprovalRequestMailerPreview < ActionMailer::Preview
  def approval_request_email
    reqs = []
    HTApprovalRequest.all.sample(3).each do |req|
      reqs << req.dup
      reqs.last[:approver] = "approver@example.com"
    end
    controller = ActionController::Base.new
    body = controller.render_to_string partial: "shared/approval_request_body"
    ApprovalRequestMailer.with(reqs: reqs, email_body: body, base_url: "http://default.invalid").approval_request_email
  end
end
