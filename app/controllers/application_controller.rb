# frozen_string_literal: true

class ApplicationController < ActionController::Base
  class NotAuthorizedError < StandardError
  end

  include Keycard::ControllerMethods

  helper_method :logged_in?, :current_user

  before_action :validate_session
  before_action :authenticate!
  protect_from_forgery with: :exception, unless: -> { authentication.csrf_safe? }
  before_action :set_csrf_cookie

  rescue_from Keycard::AuthenticationRequired, with: :redirect_to_login
  rescue_from Keycard::AuthenticationFailed, with: :authentication_failed
  rescue_from ActionController::InvalidAuthenticityToken, with: :user_not_authorized
  rescue_from NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    render_forbidden
  end

  def redirect_to_login
    if request.get?
      session[:return_to] = request.path
      redirect_to login_path
    else
      render_forbidden
    end
  end

  def authentication_failed
    render_forbidden
  end

  def render_forbidden(_exception = nil)
    render 'forbidden', status: :forbidden
  end

  def set_csrf_cookie
    cookies['CSRF-TOKEN'] = form_authenticity_token
  end

  def notary
    @notary ||= Keycard::Notary.default
  end
end
