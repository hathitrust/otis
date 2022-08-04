# frozen_string_literal: true

require "test_helper"
require "otis/registration_mover"

module Otis
  class RegistrationMoverTest < ActiveSupport::TestCase
    test "finalized user uses downcased shibboleth id" do
      shib_id = fake_shib_id
      registration = create(:ht_registration, received: Time.now,
        ip_address: Faker::Internet.public_ip_v4_address,
        env: {"HTTP_X_REMOTE_USER" => shib_id}.to_json)
      ht_user = RegistrationMover.new(registration).ht_user

      assert_equal ht_user.userid, shib_id.downcase
    end

    test "finishing registration with umich user uses uniqname" do
      uniqname = Faker::Internet.username
      umich_registration = create(:ht_registration, received: Time.now,
        ip_address: Faker::Internet.public_ip_v4_address,
        env: {"HTTP_X_REMOTE_USER" => "https://shibboleth.umich.edu/idp/shibboleth!http://www.hathitrust.org/shibboleth-sp!gobbledygook",
              "HTTP_X_SHIB_UMICHCOSIGNFACTOR" => "UMICH.EDU",
              "HTTP_X_SHIB_IDENTITY_PROVIDER" => "https://shibboleth.umich.edu/idp/shibboleth",
              "HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => "#{uniqname}@umich.edu"}.to_json)

      ht_user = RegistrationMover.new(umich_registration).ht_user
      assert_equal ht_user.userid, uniqname
    end

    test "finishing registration with umich friend user uses email" do
      email = Faker::Internet.email
      umich_friend_registration = create(:ht_registration, received: Time.now,
        ip_address: Faker::Internet.public_ip_v4_address,
        env: {"HTTP_X_REMOTE_USER" => "https://shibboleth.umich.edu/idp/shibboleth!http://www.hathitrust.org/shibboleth-sp!gobbledygook",
              "HTTP_X_SHIB_IDENTITY_PROVIDER" => "https://shibboleth.umich.edu/idp/shibboleth",
              "HTTP_X_SHIB_MAIL" => email}.to_json)

      ht_user = RegistrationMover.new(umich_friend_registration).ht_user
      assert_equal ht_user.userid, email
    end

    test "finishing registration with MFA institution creates an MFA-enabled user" do
      mfa_inst = create(:ht_institution, shib_authncontext_class: "https://refeds.org/profile/mfa")
      mfa_registration = create(:ht_registration, finished: Time.now, inst_id: mfa_inst.inst_id,
        env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json)

      ht_user = RegistrationMover.new(mfa_registration).ht_user
      assert ht_user.iprestrict.nil?
      assert ht_user.mfa?
    end

    test "finishing registration with non-MFA institution and MFA addendum uses iprestrict wildcard" do
      non_mfa_inst = create(:ht_institution, shib_authncontext_class: nil)
      mfa_addendum_registration = create(:ht_registration, mfa_addendum: true,
        finished: Time.now, inst_id: non_mfa_inst.inst_id,
        env: {"HTTP_X_REMOTE_USER" => fake_shib_id}.to_json)
      ht_user = RegistrationMover.new(mfa_addendum_registration).ht_user
      assert_equal ["any"], ht_user.iprestrict
      refute ht_user.mfa?
    end
  end

  class RegistrationMoverAuthorizerTest < ActiveSupport::TestCase
    test "CAA registration uses hathitrust_authorizer for authorizer" do
      registration = create(:ht_registration, role: "quality",
        hathitrust_authorizer: "authorizer@hathitrust.org",
        env: {"HTTP_X_REMOTE_USER" => "nobody@default.invalid"}.to_json)
      ht_user = RegistrationMover.new(registration).ht_user
      assert_equal "authorizer@hathitrust.org", ht_user.authorizer
    end

    test "ATRS registration uses auth_rep_email for authorizer and ignores hathitrust_authorizer" do
      registration = create(:ht_registration, role: "ssd",
        auth_rep_email: "authorizer@default.invalid",
        hathitrust_authorizer: nil,
        env: {"HTTP_X_REMOTE_USER" => "nobody@default.invalid"}.to_json)
      ht_user = RegistrationMover.new(registration).ht_user
      assert_equal "authorizer@default.invalid", ht_user.authorizer
    end
  end

  class RegistrationMoverInstitutionTest < ActiveSupport::TestCase
    test "finishing registration uses institution.entityID to identity_provider" do
      inst = create(:ht_institution)
      registration = create(:ht_registration, inst_id: inst.inst_id,
        env: {"HTTP_X_REMOTE_USER" => "nobody@default.invalid"}.to_json)
      ht_user = RegistrationMover.new(registration).ht_user
      assert_equal inst.entityID, ht_user.identity_provider
    end
  end

  class RegistrationMoverMergeTest < ActiveSupport::TestCase
    test "finishing re-registration merges new fields onto existing user" do
      old_inst = create(:ht_institution)
      existing_user = create(:ht_user, inst_id: old_inst.inst_id)
      new_inst = create(:ht_institution)
      registration = create(:ht_registration, applicant_email: existing_user.email,
        inst_id: new_inst.inst_id, env: {"HTTP_X_REMOTE_USER" => existing_user.email}.to_json)
      new_user = RegistrationMover.new(registration).ht_user
      assert_equal new_user, existing_user.reload
    end
  end
end
