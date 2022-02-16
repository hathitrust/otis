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
    @ip_address = ip_address
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
    @registration.ip_address = @ip_address
    @registration.env = extract_shib_env
    @registration.save!
    # Currently, there are no parameters for the controller other than the
    # token, which we do not wish to log.
    log_action(@registration, params.permit)
  end

  # For development and (maybe) testing, visiting this page will taint
  # the ip_address field with "localhost" and cause a validation error on ht_user
  # created with this registration. So we use a TEST-NET-1 value.
  def ip_address
    Rails.env.production? ? request.remote_ip : "192.0.2.1"
  end

  def extract_shib_env
    request.env.select { |k, _v| k.match(/^HTTP_X_SHIB/) || k == "HTTP_X_REMOTE_USER" }.to_json
  end
end
