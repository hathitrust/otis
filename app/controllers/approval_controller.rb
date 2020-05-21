# frozen_string_literal: true

# Responsible for collecting responses from approvers
# This controller's new/show page should be the only part of the app that
# external users have access to.
class ApprovalController < ApplicationController
  # Users who cannot access the rest of the application can still use the
  # one-time links
  skip_before_action :authorize!

  def new
    @token = params[:token]
    @req = HTApprovalRequest.find_by_token(params[:token])

    return render_not_found unless @req&.token_hash

    @user = HTUser.where(email: @req.userid).first
    # detect duplicate uses of the link beforehand so shared/approval does
    # the right thing
    @already_used = @req.received.present?
    approve unless @req.expired? || @already_used

    render 'shared/approval'
  end

  private

  def approve
    @req.received = Time.now
    @req.save!
    log
  end

  # Adapted from https://gist.github.com/redrick/2c23988368fb525c7e75
  # there is more there, including GeoIP which we may use as when we
  # address HT-1451
  def log
    rails_action = "#{params[:controller]}##{params[:action]}"
    rails_params = params.except(:controller, :action)
    details = {
      action: rails_action,
      ip_address: request.remote_ip,
      params: rails_params,
      user_agent: request.user_agent
    }.merge(ENV.select { |k, _v| k.match(/^Shib/) })
    Rails.logger.info "APPROVAL LOG: #{JSON.generate(details)}"
  end
end
