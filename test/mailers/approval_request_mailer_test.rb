# frozen_string_literal: true

require "test_helper"

class ApprovalRequestMailerTest < ActionMailer::TestCase
  def setup
    @base_url = "http://default.invalid"
    @user1 = create(:ht_user, email: "user1@example.com", approver: "approver@example.com")
    @user2 = create(:ht_user, email: "user2@example.com", approver: "approver@example.com")
    @user3 = create(:ht_user, email: "user3@example.com", approver: "another_approver@example.com")
    @req1 = create(:ht_approval_request, userid: @user1.email, approver: @user1.approver)
    @req2 = create(:ht_approval_request, userid: @user2.email, approver: @user2.approver)
    @req3 = create(:ht_approval_request, userid: @user3.email, approver: @user3.approver)
  end

  def email(reqs: [@req1], base_url: @base_url, body: "")
    ApprovalRequestMailer
      .with(reqs: reqs, base_url: base_url, body: body)
      .approval_request_email
  end

  test "email contains provided body text" do
    test_text = Faker::Lorem.paragraph
    email(body: test_text).parts.each do |p|
      assert_match test_text, p.to_s
    end
  end

  test "email contains plain-textified body text" do
    test_html = "<p>This is a <b>test</b> <i>html</i> <tt>fragment</tt></p>"
    plain_text = "This is a test html fragment"

    assert_match plain_text, email(body: test_html).text_part.to_s
  end

  test "email contains unescaped html" do
    test_html = "<p>This is a <b>test</b> <i>html</i> <tt>fragment</tt></p>"

    assert_match test_html, email(body: test_html).html_part.to_s
  end

  test "sanitizes html input" do
    test_html = "<script>unsafe</script>"

    assert_no_match test_html, email(body: test_html).html_part.to_s
  end

  test "link in email contains url with token" do
    email.parts.each do |p|
      assert_match %r{http://default.invalid/approve/#{@req1.token}}, p.to_s
    end
  end

  test "sends email for two users" do
    assert_emails 1 do
      email(reqs: [@req1, @req2]).deliver_now
    end
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

  test "email is to approver" do
    assert_equal ["approver@example.com"], email.to
  end

  test "subject is from mailer" do
    assert_equal ApprovalRequestMailer.subject, email.subject
  end

  test "fail to send email for zero users" do
    assert_raise StandardError do
      email(reqs: []).deliver_now
    end
  end

  test "fail to send email for users with different approvers" do
    assert_raise StandardError do
      emails(reqs: [@req1, @req2]).deliver_now
    end
  end
end
