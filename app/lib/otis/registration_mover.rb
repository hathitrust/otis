module Otis
  # Responsible for creating a new HTUser, populating it with the data in
  # an HTRegistration, and saving.
  class RegistrationMover
    UMICH_IDP = "https://shibboleth.umich.edu/idp/shibboleth"

    def self.user_exists?(registration)
      HTUser.where(email: registration.applicant_email).exists?
    end

    def initialize(registration)
      @registration = registration
    end

    def ht_user
      return @ht_user unless @ht_user.nil?

      @ht_user = HTUser.new(userid: userid,
        email: @registration.applicant_email, displayname: @registration.applicant_name,
        inst_id: @registration.inst_id, approver: @registration.auth_rep_email,
        authorizer: authorizer, expire_type: @registration.expire_type,
        expires: ExpirationDate.new(Time.zone.now, @registration.expire_type).default_extension_date,
        usertype: :external, access: :total, role: @registration.role)
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

    # For CAA users, hathitrust_authorizer should be present and we should use that.
    # auth_rep_email is the fallback.
    def authorizer
      if !["ssd", "ssdproxy"].include?(@registration.role) && @registration.hathitrust_authorizer.present?
        @registration.hathitrust_authorizer
      else
        @registration.auth_rep_email
      end
    end

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
