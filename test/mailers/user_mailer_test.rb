# frozen_string_literal: true

require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  def setup
    @user1 = create(:ht_user, email: 'user1@example.com', approver: 'approver@example.com')
    @req1 = create(:ht_approval_request, userid: @user1.email, approver: @user1.approver)
  end

  def email(req: @req1)
    UserMailer
      .with(req: req)
      .approval_request_user_email
  end

  test 'send email for one request' do
    assert_emails 1 do
      email.deliver_now
    end
  end

  test 'emails user' do
    assert_equal ['user1@example.com'], email.to
  end

  test 'from comes from config' do
    assert_equal [Otis.config.manager_email], email.from
  end

  test 'bcc comes from config' do
    assert_equal [Otis.config.manager_email], email.bcc
  end

  test 'reply-to comes from config' do
    assert_equal [Otis.config.reply_to_email], email.reply_to
  end

  test 'fail to send email for zero requests' do
    assert_raise StandardError do
      email(req: nil).deliver_now
    end
  end
end
