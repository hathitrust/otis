# frozen_string_literal: true

class ApplicationController < ActionController::Base
  class NotAuthorizedError < StandardError
  end

  include Keycard::ControllerMethods

  helper_method :logged_in?, :current_user

  before_action :validate_session
  before_action :authenticate!
  before_action :authorize!
  protect_from_forgery with: :exception, unless: -> { authentication.csrf_safe? }
  before_action :set_csrf_cookie

  rescue_from Keycard::AuthenticationRequired, with: :redirect_to_login
  rescue_from Keycard::AuthenticationFailed, with: :authentication_failed
  rescue_from ActionController::InvalidAuthenticityToken, with: :user_not_authorized
  rescue_from NotAuthorizedError, with: :user_not_authorized
  rescue_from ActionController::RoutingError, with: :render_not_found

  def authorize!
    return if current_user.nil?

    raise NotAuthorizedError unless Otis.config.users.include? current_user.id
  end

  private

  def user_not_authorized
    # logout
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

  def render_not_found
    render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
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
    @notary = Keycard::Notary.new(
      attributes_factory: Keycard::Request::AttributesFactory.new(finders: []),
      methods: [
        Keycard::Authentication::AuthToken.bind_class_method(:User, :authenticate_by_auth_token),
        Keycard::Authentication::SessionUserId.bind_class_method(:User, :authenticate_by_id),
        Keycard::Authentication::UserEid.bind_class_method(:User, :authenticate_by_user_eid)
      ]
    )
  end
end
