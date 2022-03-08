# frozen_string_literal: true

class HTApprovalRequestsController < ApplicationController
  before_action :fetch_requests, only: %i[show update edit]

  def create
    if params[:submit_requests]
      @added_users = add_requests(params[:ht_users])
      if @added_users.any?
        flash[:notice] = t ".added_users", users: @added_users.to_sentence
      end
      session[:added_users] = @added_users
    end
    if params[:submit_renewals]
      @renewed_users = add_renewals(params[:ht_users])
      if @renewed_users.any?
        flash[:notice] = t ".renewed_users", users: @renewed_users.to_sentence
      end
      session[:renewed_users] = @renewed_users
    end
    if params[:delete_expired]
      deleted = delete_expired
      if deleted.any?
        flash[:notice] = t ".deleted_users", users: deleted.to_sentence
      end
    end
    redirect_to action: :index
  end

  def index
    requests = HTApprovalRequest.order("approver")
    @incomplete_reqs = requests.not_renewed.map { |r| presenter r }
    @complete_reqs = requests.renewed.map { |r| presenter r }
    @added_users = session[:added_users] || []
    @renewed_users = session[:renewed_users] || []
    session.delete :added_users
    session.delete :renewed_users
  end

  def update
    begin
      ApprovalRequestMailer.with(reqs: @reqs, base_url: request.base_url,
        body: params[:email_body], subject: params[:subject]).approval_request_email.deliver_now
      @reqs.each do |req|
        next unless req.mailable?

        UserMailer.with(req: req).approval_request_user_email.deliver_now
        req.sent = Time.zone.now
        req.save!
      end
      flash[:notice] = t ".messages_sent"
    rescue => e
      flash[:alert] = e.message
    end
    redirect_to action: "show"
  end

  def status_counts
    @reqs.group_by(&:renewal_state).transform_values(&:length)
  end

  def edit
    @preview = true
    @email_body = render_to_string partial: "shared/approval_request_body"
  end

  private

  def presenter(user)
    HTApprovalRequestPresenter.new(user, controller: self, action: params[:action].to_sym)
  end

  def fetch_requests
    @reqs = HTApprovalRequest.for_approver(params[:id]).not_renewed.map do |r|
      presenter r
    end
  end

  # Add an approval request for selected users.
  # If unrenewed one already exists, silently skip over it.
  # Returns an Array of ht_user emails added to requests.
  def add_requests(emails)
    if emails.nil? || emails.empty?
      flash[:alert] = t "ht_approval_requests.create.no_selection"
      return []
    end
    adds = []
    emails.each do |e|
      next if HTApprovalRequest.where(userid: e, renewed: nil).count.positive?

      begin
        add_request e
        adds << e
      rescue => e
        flash[:alert] = e.message
      end
    end
    adds
  end

  def add_request(email)
    u = HTUser.find(email)
    HTApprovalRequest.new(ht_user: u, approver: u.approver).save!
  end

  def add_renewals(emails)
    if emails.nil? || emails.empty?
      flash[:alert] = "No users selected"
      return []
    end
    adds = []
    emails.each do |e|
      HTUser.find(e).add_or_update_renewal(approver: current_user.id)
      adds << e
    rescue HTUserRenewalError => err
      flash[:alert] = t ".errors.#{err.type}", user: e
    end
    adds
  end

  def delete_expired
    deleted = HTApprovalRequest.expired.map(&:userid)
    HTApprovalRequest.expired.destroy_all
    deleted
  end
end
