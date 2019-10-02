# frozen_string_literal: true

class SessionController < ApplicationController
  skip_before_action :validate_session, :authenticate!, :authorize!

  def new
    if login
      redirect_back_or_to root_path
    else
      default_login
    end
  end

  def create
    return forbidden! unless Otis.config.allow_impersonation

    user = User.new(params[:username])
    if user
      auto_login(user)
      redirect_back_or_to root_path
    else
      render_forbidden
    end
  end

  def destroy
    logout
    redirect_back_or_to root_path
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

  def default_login
    redirect_to shib_login_url(request.base_url + (session[:return_to] || ''))
  end

  def shib_login_url(target)
    URI("#{Otis.config.shibboleth.sp.url}/Login").tap do |url|
      url.query = URI.encode_www_form(
        target: target,
        entityID: Otis.config.shibboleth.default_idp.entity_id
      )
    end.to_s
  end
end
