# frozen_string_literal: true

class HTUsersController < ApplicationController
  before_action :fetch_user, only: %i[show edit update]

  PERMITTED_UPDATE_FIELDS = %i[userid iprestrict expires approver mfa].freeze

  def index
    users = HTUser.joins(:ht_institution).order('ht_institutions.name')
    @users = users.active.map { |u| HTUserPresenter.new(u) }
    @expired_users = users.expired.map { |u| HTUserPresenter.new(u) }
  end

  def update
    # Any extension of term counts as a renewal for our purposes.
    renewing = user_params[:expires].present? && user_params[:expires] > @user.expires.to_date.to_s
    if @user.update(user_params)
      flash[:notice] = 'User updated'
      @user.add_or_update_renewal(approver: current_user.id, force: true) if renewing
      redirect_to @user
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      fetch_user
      render 'edit'
    end
  end

  private

  def fetch_user
    @user = HTUserPresenter.new(HTUser.joins(:ht_institution).find(params[:id]))
  end

  def user_params
    params.require(:ht_user).permit(*PERMITTED_UPDATE_FIELDS)
  end
end
