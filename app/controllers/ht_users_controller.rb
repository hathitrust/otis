# frozen_string_literal: true

class HTUsersController < ApplicationController
  before_action :fetch_user, only: %i[show edit]

  PERMITTED_UPDATE_FIELDS = %i[userid displayname activitycontact approver authorizer
    usertype role access expires expire_type iprestrict mfa].freeze

  def index
    users = HTUser.joins(:ht_institution).order("ht_institutions.name")
    @users = users.active.map { |u| presenter u }
    @expired_users = users.expired.map { |u| presenter u }
    @all_users = users.map { |u| presenter u }
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

    if @user.update(user_params)
      @user.add_or_update_renewal(approver: current_user.id, force: true) if renewing
      log_action(@user, user_params)
      update_user_success
    else
      update_user_failure
    end
  end

  private

  def presenter(user)
    HTUserPresenter.new(user, controller: self, action: params[:action].to_sym)
  end

  def update_user_failure
    flash.now[:alert] = @user.errors.full_messages.to_sentence
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
      p[:mfa] == "1" ? p.merge({iprestrict: nil}) : p
    end
  end

  def users_csv
    require "csv"
    CSV.generate do |csv|
      csv << @all_users.first.csv_cols
      @all_users.each do |user|
        if params[:role_filter]&.include?(user.role)
          next
        end
        csv << user.csv_vals
      end
    end
  end
end
