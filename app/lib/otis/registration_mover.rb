module Otis
  # Responsible for creating a new HTUser, populating it with the data in
  # an HTRegistration, and saving.
  class RegistrationMover
    UMICH_IDP = "https://shibboleth.umich.edu/idp/shibboleth"

    def initialize(registration)
      @registration = registration
    end

    def ht_user
      return @ht_user unless @ht_user.nil?

      @ht_user = HTUser.new(userid: userid,
        email: @registration.dsp_email, displayname: @registration.dsp_name,
        inst_id: @registration.inst_id, approver: @registration.auth_rep_email,
        authorizer: @registration.auth_rep_email, expire_type: :expiresannually,
        expires: Time.zone.now + 1.year, usertype: :external, access: :total,
        role: :ssdproxy)
      institution = HTInstitution.find(@registration.inst_id)
      if institution.mfa?
        @ht_user.mfa = true
      else
        @ht_user.iprestrict = @registration.ip_address
      end
      @ht_user.tap do |u|
        u.save
      end
    end

    private

    # Adapted from https://github.com/hathitrust/mdp-lib/blob/master/Utils.pm#L79
    # This logic is largely because of having migrated Michigan users from
    # Cosign.
    #
    # It can go away once we either:
    #   - have (non-downcased) REMOTE_USER for all user (otis captures this at registration & renewal)
    #   - can match any form of user id in other places
    def userid
      if used_umich_idp?
        umich_uniqname
      else
        @registration.env["HTTP_X_REMOTE_USER"]
      end.downcase
    end

    def umich_uniqname
      if umich_friend_account?
        @registration.env["HTTP_X_SHIB_MAIL"]
      else
        @registration.env["HTTP_X_SHIB_EDUPERSONPRINCIPALNAME"].downcase.sub(/@umich\.edu$/, "")
      end
    end

    def umich_friend_account?
      !@registration.env["HTTP_X_SHIB_UMICHCOSIGNFACTOR"]&.match?(/UMICH\.EDU/)
    end

    def used_umich_idp?
      @registration.env["HTTP_X_SHIB_IDENTITY_PROVIDER"] == UMICH_IDP
    end
  end
end
