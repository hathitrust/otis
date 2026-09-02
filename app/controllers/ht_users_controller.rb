# frozen_string_literal: true

class HTUsersController < ApplicationController
  before_action :fetch_user, only: %i[show edit]

  PERMITTED_UPDATE_FIELDS = %i[userid displayname activitycontact approver approver_name
    authorizer usertype role access expires expire_type iprestrict mfa].freeze

  def index
    users = HTUser.includes(:ht_institution, :ht_approval_request).order("ht_institutions.name").order(HTApprovalRequest.most_recent_order)
    @users = users.active.map { |u| presenter u }
    @expired_users = users.expired.map { |u| presenter u }
    respond_to do |format|
      format.html
      format.csv do
        file_name = (params[:file_name] || "ht_users") + ".csv"
        send_data users_csv, filename: file_name
      end
    end
  end

  def update
    @user = HTUser.find(params[:id])
    # Any extension of term counts as a renewal for our purposes.
    renewing = user_params[:expires].present? && user_params[:expires] > @user.expires.to_date.to_s
    # Roll back change to user if change to renewal or approver contact fails.
    ActiveRecord::Base.transaction do
      @user.update!(user_params)
      @user.add_or_update_renewal(approver: current_user.id, force: true) if renewing
      update_approver!
      log_action(@user, user_params)
    end
    update_user_success
  rescue ActiveRecord::RecordInvalid => e
    update_user_failure(e)
  end

  private

  def presenter(user)
    HTUserPresenter.new(user, controller: self, action: params[:action].to_sym)
  end

  def update_user_failure(exception)
    failed_record = exception.record
    flash.now[:alert] = "Validation failed: " + failed_record.errors.full_messages.to_sentence + " (#{failed_record.class})"
    fetch_user
    render "edit"
  end

  def update_user_success
    flash[:notice] = t "ht_users.update.success"
    redirect_to @user
  end

  def fetch_user
    @user = presenter HTUser.joins(:ht_institution).find(params[:id])
  end

  def user_params
    @user_params ||= begin
      p = params.require(:ht_user).permit(*PERMITTED_UPDATE_FIELDS)
      # Permit :approver_name to silence "unpermitted parameter" warnings
      # but we don't want to update the user with it.
      p.delete(:approver_name)
      (p[:mfa] == "1") ? p.merge({iprestrict: nil}) : p
    end
  end

  def users_csv
    require "csv"
    all_users = @users + @expired_users
    CSV.generate do |csv|
      csv << all_users.first.csv_cols
      all_users.each do |user|
        if params[:role_filter]&.include?(user.role)
          next
        end
        csv << user.csv_vals
      end
    end
  end

  # Create or update the EA Approver contact based on approver and approver_name parameters
  def update_approver!
    return unless params[:ht_user].key?(:approver_name)

    HTContact.add_or_update(
      contact_type: HTContactType.ea_approver.id,
      email: @user.approver,
      inst_id: @user.inst_id,
      name: params[:ht_user][:approver_name]
    )
  end
end
