module Otis
  # Responsible for creating a new HTUser, populating it with the data in
  # an HTRegistration, and saving.
  class RegistrationMover
    def initialize(registration)
      @registration = registration
    end

    def ht_user
      return @ht_user unless @ht_user.nil?

      @ht_user = HTUser.new(userid: @registration.env["HTTP_X_REMOTE_USER"],
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
  end
end
