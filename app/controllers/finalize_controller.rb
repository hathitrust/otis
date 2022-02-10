# frozen_string_literal: true

# Responsible for collecting registration responses from prospective users.
# As with approval requests, this controller's new page should be
# the only part of the app that such external users have access to.

class FinalizeController < ApplicationController
  def new
    @token = params[:token]
    @registration = HTRegistration.find_by_token(params[:token])
    return render_not_found unless @registration&.token_hash

    @already_used = @registration.received.present?
    @ip_address = request.remote_ip
    # WHOIS text is not appropriate content for a signup page.
    # This can be moved into a <pre> block in a ht_registration -> ht_user transmogrification page.
    # @whois = Whois::Client.new.lookup(@ip_address)
    @institution = HTInstitutionPresenter.new @registration.ht_institution
    @message_type = if @institution.entityID && @institution.shib_authncontext_class
      :success_mfa
    elsif @registration.mfa_addendum
      :success_mfa_addendum
    else
      :success_static_ip
    end
    finalize unless @registration.expired? || @already_used
  end

  # Users who cannot access the rest of the application can still use the
  # one-time links
  def authorize!
  end

  private

  def finalize
    @registration.received = Time.zone.now
    @registration.save!
    # Currently, there are no parameters for the controller other than the
    # token, which we do not wish to log.
    log_action(@registration, params.permit)
  end
end
