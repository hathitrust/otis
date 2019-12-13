# frozen_string_literal: true

class HTUsersController < ApplicationController
  before_action :fetch_user, only: %i[show edit update]

  PERMITTED_UPDATE_FIELDS = [:userid, :iprestrict, :expires, :approver]

  def index
    if params[:email]
      @users = HTUser.joins(:ht_institution).where('email LIKE ?', "%#{params[:email]}%").order(:userid)
      flash.now[:alert] = "No results for '#{params[:email]}'" if @users.empty?
    else
      @users = HTUser.joins(:ht_institution).order('ht_institutions.name')
    end
  end

  def update
    if @user.update(user_params)
      flash[:notice] = 'User updated'
      redirect_to @user
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      fetch_user
      render 'edit'
    end
  end

  private

  def fetch_user
    @user = HTUser.joins(:ht_institution).find(params[:id])
  end

  def user_params
    params.require(:ht_user).permit(*PERMITTED_UPDATE_FIELDS)
  end
end
