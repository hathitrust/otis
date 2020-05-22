# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def approval_request_user_email
    @req = params[:req]
    @base_url = params[:base_url]
    raise StandardError, 'Cannot send email without an approval request' unless @req.present?

    @user = HTUser.find(@req.userid)
    mail(to: @req.userid, subject: 'HathiTrust Elevated Access Status')
  end
end
