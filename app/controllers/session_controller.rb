# frozen_string_literal: true

class SessionController < ApplicationController
  skip_before_action :authenticate!

  def new
    if login
      redirect_back_or_to '/'
    else
      render 'shared/login_form'
    end
  end

  def create
    username = params[:username]
    user = User.find_by_username(username)
    if user
      auto_login(user)
      redirect_back_or_to '/'
    else
      render_unauthorized
    end
  end

  def destroy
    logout
    redirect_back_or_to '/'
  end

  private

  def redirect_back_or_to(destination)
    destination = session[:return_to] || destination || '/'
    session.delete(:return_to)
    redirect_to destination
  end

  def forbidden!
    head 403
  end
end
