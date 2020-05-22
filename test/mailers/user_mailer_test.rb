# frozen_string_literal: true

require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  def setup
    @base_url = 'http://default.invalid'
    @user1 = create(:ht_user, email: 'user1@example.com', approver: 'approver@example.com')
    @req1 = create(:ht_approval_request, userid: @user1.email, approver: @user1.approver)
  end

  test 'send email for one request' do
    email = UserMailer
            .with(req: @req1, base_url: @base_url)
            .approval_request_user_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [ApplicationMailer.default[:from]], email.from
    assert_equal ['user1@example.com'], email.to
  end

  test 'fail to send email for zero requests' do
    assert_raise StandardError do
      UserMailer
        .with(req: nil, base_url: @base_url)
        .approval_request_user_email
        .deliver_now
    end
  end
end
