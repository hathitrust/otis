# frozen_string_literal: true

class HTUsersController < ApplicationController
  before_action :fetch_user, only: %i[show edit update]

  def index
    if params[:email]
      @users = HTUser.where('email LIKE ?', "%#{params[:email]}%").order(:userid)
      flash.now[:alert] = "No results for '#{params[:email]}'" unless @users.count.positive?
    else
      @users = HTUser.all.order(:userid)
    end
  end

  def update
    if @user.update(user_params)
      flash[:notice] = 'User updated'
      redirect_to @user
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      @user = HTUser.find(Base64.decode64(params[:id]))
      render 'edit'
    end
  end

  private

  # ht_users.userid entries can include periods and @ signs, which messes up routing.
  # So we wrap it in Base64 wherever we need to pass it around.
  # A better solution would be to modify the ht_users schema to use integral primary key.
  def fetch_user
    @user = HTUser.find(Base64.decode64(params[:id]))
  end

  def user_params
    params.require(:ht_user).permit(:userid, :iprestrict)
  end
end
