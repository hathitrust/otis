# frozen_string_literal: true

require "test_helper"

class RegistrationMailerTest < ActionMailer::TestCase
  def setup
    @reg = create(:ht_registration, applicant_email: "user@example.com")
  end

  def email(reg: @reg)
    RegistrationMailer.with(registration: reg, base_url: "example.com", body: "test body")
      .registration_email
  end

  test "send email for one request" do
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "emails user" do
    assert_equal ["user@example.com"], email.to
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

  test "fail to send email for zero requests" do
    assert_raise StandardError do
      email(reg: nil).deliver_now
    end
  end

  test "mail has HathiTrust logo PNG attachment" do
    assert_match %r{image/png}, email.attachments[0].content_type
  end

  test "mailer raises if body is not present" do
    assert_raise StandardError do
      RegistrationMailer.with(registration: reg, base_url: "example.com")
    end
  end
end
