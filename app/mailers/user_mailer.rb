# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def approval_request_user_email
    @req = params[:req]
    raise StandardError, "Cannot send email without an approval request" unless @req.present?

    @user = HTUser.find(@req.userid)
    attachments.inline["HathiTrust_logo.png"] = File.read("#{Rails.root}/app/assets/images/HathiTrust_logo.png")
    mail(to: @req.userid, subject: "HathiTrust Elevated Access Status")
  end
end
