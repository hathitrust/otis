# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def approval_request_companion_email
    req = HTApprovalRequest.all.sample(1).first
    UserMailer.with(req: req, base_url: 'www.example.com').approval_request_user_email
  end
end
