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
end
