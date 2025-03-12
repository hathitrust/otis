# frozen_string_literal: true

require "test_helper"

class HTUserTest < ActiveSupport::TestCase
  test "validation passes" do
    assert build(:ht_user).valid?
  end

  test "whitespace stripped by default" do
    user = create(
      :ht_user,
      approver: " user2@default.invalid ",
      email: " user1@default.invalid ",
      displayname: " User Name ",
      activitycontact: " activitycontact@default.invalid ",
      authorizer: " authorizer@default.invalid "
    )
    assert user.valid?
    user.reload
    assert_equal "user2@default.invalid", user[:approver]
    assert_equal "user1@default.invalid", user[:email]
    assert_equal "User Name", user[:displayname]
    assert_equal "activitycontact@default.invalid", user[:activitycontact]
    assert_equal "authorizer@default.invalid", user[:authorizer]
  end

  test "iprestrict validation fails" do
    assert_not build(:ht_user, iprestrict: "127.0.0.1.1").valid?
  end

  test "iprestrict escaping and unescaping" do
    user = build(:ht_user, iprestrict: "1.2.3.4")
    assert_equal '^1\.2\.3\.4$', user[:iprestrict]
    assert_equal ["1.2.3.4"], user.iprestrict
  end

  test "iprestrict with whitespace" do
    user = build(:ht_user, iprestrict: " 1.2.3.4 ")
    assert_equal '^1\.2\.3\.4$', user[:iprestrict]
    assert_equal ["1.2.3.4"], user.iprestrict
  end

  test "expires validation rejects various bogative timestamps" do
    user = build(:ht_user, expires: "2020-21-01 00:00:00")
    assert_not user.valid?
    user.expires = "2020-01-91"
    assert_not user.valid?
    user.expires = "2020-01-01 99:99:99"
    assert_not user.valid?
    user.expires = "now"
    assert_not user.valid?
    user.expires = nil
    assert_not user.valid?
  end

  test "expires validation produces localized error on bogative timestamp" do
    user = build(:ht_user, expires: "2020-21-XX")
    assert_not user.valid?
    assert user.errors.full_messages.any? %r{valid timestamp}
  end
end

class HTUserInstitutionTest < ActiveSupport::TestCase
  def setup
    @inst1 = create(:ht_institution, entityID: "http://ok.com", inst_id: "ok")
    @inst2 = create(:ht_institution, entityID: "http://bogus.com", inst_id: "bogus")
    @user1 = create(:ht_user, identity_provider: "http://bogus.com", inst_id: "ok")
  end

  test "joins on inst_id instead of deprecated identity_provider" do
    assert_equal @inst1, @user1.ht_institution
  end
end

class HTUserActiveExpiredTest < ActiveSupport::TestCase
  def setup
    @active = create(:ht_user, :active)
    @expired = create(:ht_user, :expired)
  end

  test "#active returns only active users" do
    assert_includes(HTUser.active, @active)
    assert_not_includes(HTUser.active, @expired)
  end

  test "#expired returns only expired users" do
    assert_includes(HTUser.expired, @expired)
    assert_not_includes(HTUser.expired, @active)
  end
end

class HTUserExpiringSoon < ActiveSupport::TestCase
  def setup
    @expiring_user = build(:ht_user, expires: Date.today + 10)
    @expired_user = build(:ht_user, expires: Date.today - 10)
    @safe_user = build(:ht_user, expires: Date.today + 100)
  end

  # Do assert_in_delta because we're getting a full timestamp but
  # rounding to days
  test "#days_until_expiration" do
    assert_in_delta(10, @expiring_user.days_until_expiration, 1)
    assert_in_delta(-10, @expired_user.days_until_expiration, 1)
    assert_in_delta(100, @safe_user.days_until_expiration, 1)
  end

  test "#expiring_soon is correct for those in and outside the range" do
    assert(@expiring_user.expiring_soon?)
    assert_not(@expired_user.expiring_soon?)
    assert_not(@safe_user.expiring_soon?)
  end

  test "Expiration date can be set via #expires" do
    user = build(:ht_user, expires: Date.today - 10)
    assert user.expired?
    assert user.expiration_date.expired?

    user.expires = Date.today + 100
    assert_not user.expired?
    assert_not user.expiration_date.expired?
  end

  test "Extend date by default period" do
    initial_date = "2019-01-01"
    u1 = build(:ht_user, expires: initial_date, expire_type: "expirescustom60")
    u1.extend_by_default_period!
    assert_equal Date.parse(initial_date) + 60, u1.expires.to_date
  end
end

class HTUserExpiringSoonScope < ActiveSupport::TestCase
  def setup
    @expiring_user = create(:ht_user, expires: Date.today + 5)
    @expired_user = create(:ht_user, expires: Date.today - 10)
    @safe_user = create(:ht_user, expires: Date.today + 100)
  end

  test "expiring_soon scope is correctly limited" do
    expiring_soon_users = HTUser.expiring_soon
    assert(expiring_soon_users.count == 1)
    assert(expiring_soon_users[0].id == @expiring_user.id)
  end
end

class HTUserMFA < ActiveSupport::TestCase
  def setup
    @mfa_user = build(:ht_user_mfa)
  end

  test "User with MFA and no iprestrict is valid" do
    assert_equal true, @mfa_user.mfa
    assert_nil @mfa_user.iprestrict
    assert @mfa_user.valid?
  end
end

class HTUserMultipleIprestrict < ActiveSupport::TestCase
  def setup
    @multi_ip_user = build(:ht_user, mfa: false, iprestrict: "1.2.3.4, 5.6.7.8")
    @bogus_multi_ip_user = build(:ht_user, mfa: false, iprestrict: "1.2.3.4, 1.2.3.4.5")
  end

  test "User with multiple iprestrict is valid" do
    assert_equal false, @multi_ip_user.mfa
    assert_instance_of Array, @multi_ip_user.iprestrict
    assert @multi_ip_user.valid?
  end

  test "User with one of two IPs bogus is not valid" do
    assert_equal '^1\.2\.3\.4$|^1\.2\.3\.4\.5$', @bogus_multi_ip_user [:iprestrict]
    assert_equal ["1.2.3.4", "1.2.3.4.5"], @bogus_multi_ip_user.iprestrict
    assert_not @bogus_multi_ip_user.valid?
    assert_not_empty @bogus_multi_ip_user.errors.messages[:iprestrict]
  end
end

class HTUserRenewal < ActiveSupport::TestCase
  def setup
    @expiresannually_user = build(:ht_user, expires: Time.zone.now, expire_type: "expiresannually")
    @expiresbiannually_user = build(:ht_user, expires: Time.zone.now, expire_type: "expiresbiannually")
    @expirescustom90_user = build(:ht_user, expires: Time.zone.now, expire_type: "expirescustom90")
    @expirescustom60_user = build(:ht_user, expires: Time.zone.now, expire_type: "expirescustom60")
    @unknown_user = build(:ht_user, expires: Time.zone.now, expire_type: "unknown")
  end

  test "User expiresannually" do
    @expiresannually_user.renew!
    assert_in_delta(365, @expiresannually_user.days_until_expiration, 1)
  end

  test "User expiresbiannually" do
    @expiresbiannually_user.renew!
    assert_in_delta(730, @expiresbiannually_user.days_until_expiration, 1)
  end

  test "User expirescustom90" do
    @expirescustom90_user.renew!
    assert_in_delta(90, @expirescustom90_user.days_until_expiration, 5)
  end

  test "User expirescustom60" do
    @expirescustom60_user.renew!
    assert_in_delta(60, @expirescustom60_user.days_until_expiration, 3)
  end

  test "User with unknown expire_type" do
    assert_raise StandardError do
      @unknown_user.renew!
    end
  end
end

class HTUserUpdateApprover < ActiveSupport::TestCase
  def setup
    @user = create(:ht_user, approver: "somebody@example.com")
  end

  test "deletes non-approved request when updating approver" do
    create(:ht_approval_request, ht_user: @user)
    @user.reload
    @user.approver = "somebodyelse@example.com"
    assert_difference -> { HTApprovalRequest.count }, -1 do
      @user.save
    end
  end

  test "does not delete approved request when updating approver" do
    create(:ht_approval_request, ht_user: @user, received: Faker::Time.backward)

    @user.reload
    @user.approver = "somebodyelse@example.com"
    assert_no_difference -> { HTApprovalRequest.count } do
      @user.save
    end
  end

  test "does not delete manual renewal when updating approver" do
    @user.add_or_update_renewal(approver: "staff@whatever.edu", force: true)

    @user.reload
    @user.approver = "somebodyelse@example.com"
    assert_no_difference -> { HTApprovalRequest.count } do
      @user.save
    end
  end
end

class HTUserManualExpire < ActiveSupport::TestCase
  def setup
    @user = create(:ht_user, approver: "somebody@example.com")
  end

  test "deletes non-approved request when manually expiring user" do
    create(:ht_approval_request, ht_user: @user, sent: Faker::Time.backward)
    @user.reload
    @user.expires = Time.zone.now
    assert_difference -> { HTApprovalRequest.count }, -1 do
      @user.save
    end
  end

  test "does not delete approved request when manually expiring user" do
    create(:ht_approval_request, ht_user: @user, received: Faker::Time.backward)

    @user.reload
    @user.expires = Time.zone.now
    assert_no_difference -> { HTApprovalRequest.count } do
      @user.save
    end
  end
end
