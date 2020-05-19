# frozen_string_literal: true

class HTApprovalRequestsController < ApplicationController
  before_action :fetch_requests, only: %i[show update edit]

  def index
    @reqs = HTApprovalRequest.order('approver')
    @added = []
    return unless params[:submit_req]

    add_requests(params[:ht_users])
    flash.now[:notice] = "Added #{'request'.pluralize(@added.count)} for #{@added.join ','}" if @added.count.positive?
  end

  def update # rubocop:disable Metrics/MethodLength
    begin
      ApprovalRequestMailer.with(reqs: @reqs).approval_request_email.deliver_now
      @reqs.each do |req|
        next unless req.mailable?

        req.sent = Time.now
        req.save!
      end
      flash[:notice] = 'Message sent'
    rescue StandardError => e
      flash[:alert] = e.message
    end
    redirect_to action: 'show'
  end

  def status_counts
    @reqs.group_by(&:renewal_state).map { |k, v| [k, v.length] }.to_h
  end

  private

  def fetch_requests
    @reqs = HTApprovalRequest.not_renewed_for_approver(params[:id])
  end

  # Add an approval request for selected users.
  # If one already exists, silently skip over it.
  def add_requests(emails) # rubocop:disable Metrics/MethodLength
    if emails.nil? || emails.empty?
      flash.now[:alert] = 'No users selected'
      return
    end
    emails.each do |e|
      next if HTApprovalRequest.where(userid: e).count.positive?

      begin
        add_request e
        @added << e
      rescue StandardError => e
        flash.now[:alert] = e.message
      end
    end
  end

  def add_request(email)
    u = HTUser.where(email: email).first
    raise StandardError, "Unknown user '#{email}'" if u.nil?

    HTApprovalRequest.new(userid: u.email, approver: u.approver).save!
  end
end
