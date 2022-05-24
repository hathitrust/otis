# frozen_string_literal: true

# Used by DailyDigestMailer to report on action items requiring attention from
# administrator.
module Otis
  class DailyDigest
    attr_reader :ready_registrations, :expired_registrations,
      :ready_approval_requests, :expired_approval_requests,
      :expiring_users
    def self.send
      digest = DailyDigest.new
      DailyDigestMailer.with(digest: digest).daily_digest_email.deliver_now
    end

    def initialize
      @ready_registrations = HTRegistration.ready
      @expired_registrations = HTRegistration.expired
      @ready_approval_requests = HTApprovalRequest.approved.not_renewed
      @expired_approval_requests = HTApprovalRequest.expired
      @expiring_users = HTUser.expiring_soon
    end
  end
end
