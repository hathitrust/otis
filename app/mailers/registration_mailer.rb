# frozen_string_literal: true

class RegistrationMailer < ApplicationMailer
  def self.subject
    "HathiTrust Elevated Access Registration"
  end

  def registration_email
    @registration = params[:registration]
    @base_url = params[:base_url]
    @body = params[:body]
    raise StandardError, "Cannot send email without a registration" unless @registration.present?
    raise StandardError, "Cannot send email without a base URL" unless @base_url.present?
    raise StandardError, "Cannot send email without email body" unless @body.present?

    @subject = params[:subject] || RegistrationMailer.subject
    add_email_signature_logo
    mail(to: @registration.applicant_email, subject: @subject)
  end
end
