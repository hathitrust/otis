# frozen_string_literal: true

class DailyDigestMailerPreview < ActionMailer::Preview
  def daily_digest_email
    digest = Otis::DailyDigest.new
    DailyDigestMailer.with(digest: digest).daily_digest_email
  end
end
