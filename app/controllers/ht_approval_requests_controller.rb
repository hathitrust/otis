# frozen_string_literal: true

class HTApprovalRequestsController < ApplicationController
  before_action :fetch_requests, only: %i[show update edit]

  def create # rubocop:disable Metrics/MethodLength
    if params[:submit_requests]
      @added_users = add_requests(params[:ht_users])
      flash[:notice] = "Added #{'request'.pluralize(@added_users.count)} for #{@added_users.join ', '}" if @added_users.count.positive?
      session[:added_users] = @added_users
    end
    if params[:submit_renewals]
      @renewed_users = add_renewals(params[:ht_users])
      flash[:notice] = "Renewed #{@renewed_users.join ', '}" if @renewed_users.count.positive?
      session[:renewed_users] = @renewed_users
    end
    redirect_to action: :index
  end

  def index
    @reqs = HTApprovalRequest.order('approver')
    @added_users = session[:added_users] || []
    @renewed_users = session[:renewed_users] || []
    session.delete :added_users
    session.delete :renewed_users
  end

  def update # rubocop:disable Metrics/MethodLength
    begin
      ApprovalRequestMailer.with(reqs: @reqs, base_url: request.base_url, body: params[:email_body]).approval_request_email.deliver_now
      @reqs.each do |req|
        next unless req.mailable?

        UserMailer.with(req: req).approval_request_user_email.deliver_now
        req.sent = Time.now
        req.save!
      end
      flash[:notice] = 'Messages sent'
    rescue StandardError => e
      flash[:alert] = e.message
    end
    redirect_to action: 'show'
  end

  def status_counts
    @reqs.group_by(&:renewal_state).transform_values(&:length)
  end

  def edit
    @preview = true
    @email_body = render_to_string partial: 'shared/approval_request_body'
  end

  private

  def fetch_requests
    @reqs = HTApprovalRequest.for_approver(params[:id]).not_renewed
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
    u = HTUser.find(email)
    HTApprovalRequest.new(ht_user: u, approver: u.approver).save!
  end

  def add_renewals(emails) # rubocop:disable Metrics/MethodLength
    if emails.nil? || emails.empty?
      flash[:alert] = 'No users selected'
      return []
    end
    adds = []
    emails.each do |e|
      HTUser.find(e).add_or_update_renewal(approver: current_user.id)
      adds << e
    rescue StandardError => e
      flash[:alert] = e.message
    end
    adds
  end
end
