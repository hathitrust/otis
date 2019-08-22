# frozen_string_literal: true

class SessionController < ApplicationController
  skip_before_action :authenticate!, :authorize!

  def new
    if login
      redirect_back_or_to '/'
    elsif Otis.config.allow_impersonation
      render 'shared/login_form'
    else
      render_unauthorized
    end
  end

  def create
    return forbidden! unless Otis.config.allow_impersonation

    user = User.new(params[:username])
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
