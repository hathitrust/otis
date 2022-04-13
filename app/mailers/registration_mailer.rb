# frozen_string_literal: true

class RegistrationMailer < ApplicationMailer
  def self.subject
    "HathiTrust Elevated Access Registration"
  end

  def registration_email
    @registration = params[:registration]
    @base_url = params[:base_url]
    raise StandardError, "Cannot send email without a registration" unless @registration.present?
    raise StandardError, "Cannot send email without a base URL" unless @base_url.present?

    @subject = params[:subject] || RegistrationMailer.subject
    @body = params[:body]
    attachments.inline["HathiTrust_logo.png"] = File.read("#{Rails.root}/app/assets/images/HathiTrust_logo.png")
    mail(to: @registration.applicant_email, subject: @subject)
  end
end
