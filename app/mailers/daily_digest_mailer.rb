# frozen_string_literal: true

class DailyDigestMailer < ApplicationMailer
  def daily_digest_email
    @digest = params[:digest]
    raise StandardError, "Cannot send email without a digest" unless @digest.present?

    add_email_signature_logo
    mail(to: Otis.config.manager_email, subject: "OTIS Daily Digest")
  end
end
