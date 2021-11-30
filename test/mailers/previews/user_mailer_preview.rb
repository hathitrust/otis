# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def approval_request_companion_email
    req = ApprovalRequest.all.sample(1).first
    UserMailer.with(req: req).approval_request_user_email
  end
end
