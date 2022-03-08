# frozen_string_literal: true

class RegistrationMailer < ApplicationMailer
  def self.subject
    "HathiTrust Elevated Access Registration"
  end

  def registration_email
    @registration = params[:registration]
    @subject = params[:subject] || RegistrationMailer.subject
    raise StandardError, "Cannot send email without a registration" unless @registration.present?
    @base_url = params[:base_url]
    @body = params[:body]
    mail(to: @registration.dsp_email, subject: @subject)
  end
end
