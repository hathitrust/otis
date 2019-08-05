# frozen_string_literal: true

class HTUsersController < ApplicationController
  def index
    if params[:email]
      @users = HTUser.where('email LIKE ?', "%#{params[:email]}%").order(:userid)
    else
      @users = HTUser.all.order(:userid)
    end
  end

  # ht_users.userid entries can include periods and @ signs, which messes up routing.
  def show
    @user = HTUser.find(Base64.decode64(params[:id]))
  end
end
