# frozen_string_literal: true

class SessionController < ApplicationController
  skip_before_action :validate_session, :authenticate!, :authorize!

  def new
    if login
      redirect_back_or_to default_path
    else
      redirect_to shib_login_url
    end
  end

  def create
    return forbidden! unless Otis.config.allow_impersonation

    user = User.new(params[:username])
    if user
      auto_login(user)
      redirect_back_or_to default_path
    else
      render_forbidden
    end
  end

  def destroy
    path = default_path
    logout
    redirect_back_or_to path
  end

  private

  def redirect_back_or_to(destination)
    destination = session[:return_to] || destination || root_path
    session.delete(:return_to)
    redirect_to destination
  end

  def forbidden!
    head 403
  end

  def shib_login_url(target = request.original_url)
    URI(Otis.config.shibboleth.url).tap do |url|
      url.query = URI.encode_www_form(
        target: target
      )
    end.to_s
  end
end
