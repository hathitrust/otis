# frozen_string_literal: true

require "test_helper"

module Otis
  class DailyDigestTest < ActiveSupport::TestCase
    def setup
      @ready_registration = create(:ht_registration, sent: Time.now - 30.days,
        received: Time.now - 1.day, finished: nil)
      @unready_registration = create(:ht_registration, sent: Time.now - 1.day,
        received: nil, finished: nil)
      @expired_registration = create(:ht_registration, sent: Time.now - 30.days,
        received: nil, finished: nil)
      @ready_approval_request = create(:ht_approval_request, sent: Time.now - 30.days,
        received: Time.now - 1.day, renewed: nil)
      @unready_approval_request = create(:ht_approval_request, sent: Time.now - 1.day,
        received: nil, renewed: nil)
      @expired_approval_request = create(:ht_approval_request, sent: Time.now - 30.days,
        received: nil, renewed: nil)
      @expiring_user = create :ht_user, expires: Date.today + 10
      @nonexpiring_user = create :ht_user, expires: Date.today + 100
    end

    test "create functional Daily Digest" do
      dd = DailyDigest.new
      assert_not_nil dd
      assert_not_nil dd.ready_registrations
      assert_not_nil dd.expired_registrations
      assert_not_nil dd.ready_approval_requests
      assert_not_nil dd.expired_approval_requests
      assert_not_nil dd.expiring_users
    end

    test "ready registrations reported correctly" do
      dd = DailyDigest.new
      assert dd.ready_registrations.include? @ready_registration
      assert dd.ready_registrations.exclude? @unready_registration
      assert dd.ready_registrations.exclude? @expired_registration
    end

    test "expired registrations reported correctly" do
      dd = DailyDigest.new
      assert dd.expired_registrations.include? @expired_registration
      assert dd.expired_registrations.exclude? @ready_registration
      assert dd.expired_registrations.exclude? @unready_registration
    end

    test "ready approval requests reported correctly" do
      dd = DailyDigest.new
      assert dd.ready_approval_requests.include? @ready_approval_request
      assert dd.ready_approval_requests.exclude? @unready_approval_request
      assert dd.ready_approval_requests.exclude? @expired_approval_request
    end

    test "expired approval requests reported correctly" do
      dd = DailyDigest.new
      assert dd.expired_approval_requests.include? @expired_approval_request
      assert dd.expired_approval_requests.exclude? @ready_approval_request
      assert dd.expired_approval_requests.exclude? @unready_approval_request
    end

    test "expiring users reported correctly" do
      dd = DailyDigest.new
      assert dd.expiring_users.include? @expiring_user
      assert dd.expiring_users.exclude? @nonexpiring_user
    end

    test "send Daily Digest" do
      assert_nothing_raised do
        DailyDigest.send
      end
    end
  end
end
