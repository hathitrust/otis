# frozen_string_literal: true

require "test_helper"

class DailyDigestMailerTest < ActionMailer::TestCase
  def setup
    # Give it at least one thing to report.
    create(:ht_user, expires: Date.today - 10)
    @digest = Otis::DailyDigest.new
  end

  def email(digest: @digest)
    DailyDigestMailer.with(digest: digest).daily_digest_email
  end

  test "sends exactly one email" do
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "to comes from config" do
    assert_equal [Otis.config.manager_email], email.to
  end

  test "from comes from config" do
    assert_equal [Otis.config.manager_email], email.from
  end

  test "bcc comes from config" do
    assert_equal [Otis.config.manager_email], email.bcc
  end

  test "reply-to comes from config" do
    assert_equal [Otis.config.reply_to_email], email.reply_to
  end

  test "raise if digest is omitted" do
    assert_raise StandardError do
      email(digest: nil).deliver_now
    end
  end

  test "mail has HathiTrust logo PNG attachment" do
    assert_match %r{image/png}, email.attachments[0].content_type
  end
end
