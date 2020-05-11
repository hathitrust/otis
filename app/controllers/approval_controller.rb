# frozen_string_literal: true

# Responsible for collecting responses from approvers
# This controller's new/show page should be the only part of the app that
# external users have access to.
class ApprovalController < ApplicationController
  def new
    @token = params[:token]
    @req = HTApprovalRequest.find_by_token(params[:token])
    if @req
      raise NotAuthorizedError unless current_user.id == @req.approver

      @user = HTUser.where(email: @req.userid).first
      approve unless @req.expired?
    end
    render 'shared/approval'
  end

  private

  def approve
    @req.received = Time.now
    @req.save!
    @user.renew
    log
  end

  # Adapted from https://gist.github.com/redrick/2c23988368fb525c7e75
  def log
    rails_action = "#{params[:controller]}##{params[:action]}"
    rails_params = params.except(:controller, :action)
    details = { action: rails_action,
                ip_address: request.remote_ip,
                params: rails_params,
                user_agent: request.user_agent }
    ENV.each do |k, v|
      details[v] = k if k.match(/^Shib/)
    end
    Rails.logger.info "RENEWAL LOG: #{JSON.generate(details)}"
  end
end
