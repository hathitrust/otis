# frozen_string_literal: true

# Responsible for collecting responses from approvers
# This controller's new/show page should be the only part of the app that
# external users have access to.
class ApprovalController < ApplicationController
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

  # Users who cannot access the rest of the application can still use the
  # one-time links
  def authorize!; end

  private

  def approve
    @req.received = Time.zone.now
    @req.save!
    # Currently, there are no parameters for the controller other than the
    # token, which we do not wish to log.
    log_action(HTUserLog.new(ht_user: @user), params.permit)
  end
end
