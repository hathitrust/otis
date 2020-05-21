# frozen_string_literal: true

class HTApprovalRequestsController < ApplicationController
  before_action :fetch_requests, only: %i[show update edit]

  def create
    return unless params[:submit_req]

    adds = add_requests(params[:ht_users])
    flash[:notice] = "Added #{'request'.pluralize(adds.count)} for #{adds.join ', '}" if adds.count.positive?
    redirect_to action: :index
    session[:added_users] = adds
  end

  def index
    @reqs = HTApprovalRequest.order('approver')
    @added_users = session[:added_users] || []
  end

  def update # rubocop:disable Metrics/MethodLength
    begin
      ApprovalRequestMailer.with(reqs: @reqs, base_url: request.base_url).approval_request_email.deliver_now
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

  def edit
    @preview = true
  end

  private

  def fetch_requests
    @reqs = HTApprovalRequest.not_renewed_for_approver(params[:id])
  end

  # Add an approval request for selected users.
  # If one already exists, silently skip over it.
  # Returns an Array of ht_user emails added to requests.
  def add_requests(emails) # rubocop:disable Metrics/MethodLength
    if emails.nil? || emails.empty?
      flash[:alert] = 'No users selected'
      return []
    end
    adds = []
    emails.each do |e|
      next if HTApprovalRequest.where(userid: e).count.positive?

      begin
        add_request e
        adds << e
      rescue StandardError => e
        flash[:alert] = e.message
      end
    end
    adds
  end

  def add_request(email)
    u = HTUser.where(email: email).first
    raise StandardError, "Unknown user '#{email}'" if u.nil?

    HTApprovalRequest.new(userid: u.email, approver: u.approver).save!
  end
end
