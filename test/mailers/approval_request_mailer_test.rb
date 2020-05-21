# frozen_string_literal: true

require 'test_helper'

class ApprovalRequestMailerTest < ActionMailer::TestCase
  def setup
    @base_url = 'http://default.invalid'
    @user1 = create(:ht_user, email: 'user1@example.com', approver: 'approver@example.com')
    @user2 = create(:ht_user, email: 'user2@example.com', approver: 'approver@example.com')
    @user3 = create(:ht_user, email: 'user3@example.com', approver: 'another_approver@example.com')
    @req1 = create(:ht_approval_request, userid: @user1.email, approver: @user1.approver)
    @req2 = create(:ht_approval_request, userid: @user2.email, approver: @user2.approver)
    @req3 = create(:ht_approval_request, userid: @user3.email, approver: @user3.approver)
  end

  test 'link in email contains url with token' do
    email = ApprovalRequestMailer
            .with(reqs: [@req1], base_url: @base_url)
            .approval_request_email

    email.parts.each do |p|
      assert_match %r{http://default.invalid/approve/#{@req1.token}}, p.to_s
    end
  end

  test 'send email for two users' do
    email = ApprovalRequestMailer
            .with(reqs: [@req1, @req2], base_url: @base_url)
            .approval_request_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [ApplicationMailer.default[:from]], email.from
    assert_equal ['approver@example.com'], email.to
    assert_equal ApprovalRequestMailer.subject, email.subject
    # assert_equal read_fixture('approval_request').join, email.body.to_s
  end

  test 'fail to send email for zero users' do
    assert_raise StandardError do
      ApprovalRequestMailer
        .with(reqs: [], base_url: @base_url)
        .approval_request_email
        .deliver_now
    end
  end

  test 'fail to send email for users with different approvers' do
    assert_raise StandardError do
      ApprovalRequestMailer
        .with(reqs: [@req1, @req3], base_url: @base_url)
        .approval_request_email
        .deliver_now
    end
  end
end
