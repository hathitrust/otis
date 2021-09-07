# frozen_string_literal: true

class ApplicationController < ActionController::Base
  class NotAuthorizedError < StandardError
  end

  include Keycard::ControllerMethods

  helper_method :logged_in?, :current_user, :can?

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

    raise NotAuthorizedError unless can?(params[:action], params[:controller], current_user)
  end

  def can?(action, resource, user = current_user)
    res = Checkpoint::Resource::AllOfType.new(resource)
    Checkpoint::Query::ActionPermitted.new(user, action, res, authority: Services.checkpoint).true?
  end

  # This could be replaced by a landing page that is accessible
  # to everyone.
  def default_path
    return ht_institutions_path unless can?(:index, :ht_users)

    root_path
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
    render "forbidden", status: :forbidden
  end

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = form_authenticity_token
  end

  def attributes_factory
    @attributes_factory ||= Keycard::Request::AttributesFactory.new(finders: [])
  end

  def keycard_attributes
    attributes_factory.for(request).all
  end

  def notary
    @notary ||= Keycard::Notary.new(
      attributes_factory: attributes_factory,
      methods: [
        Keycard::Authentication::AuthToken.bind_class_method(:User, :authenticate_by_auth_token),
        Keycard::Authentication::SessionUserId.bind_class_method(:User, :authenticate_by_id),
        Keycard::Authentication::UserEid.bind_class_method(:User, :authenticate_by_user_eid),
        Otis::Authentication::UserPid.bind_class_method(:User, :authenticate_by_user_pid)
      ]
    )
  end

  # Adapted from https://gist.github.com/redrick/2c23988368fb525c7e75
  # there is more there, including GeoIP which we may use as when we
  # address HT-1451
  def log_action(obj, permitted_params)
    raise UnfilteredParameters unless permitted_params.permitted?

    raise "Unable to extract object id from #{obj.inspect}" if obj.id.blank?
    rails_action = "#{params[:controller]}##{params[:action]}"
    log_entry = HTLog.new(model: obj.resource_type.to_s.camelize, objid: obj.id)
    log_entry.data = {
      action: rails_action,
      ip_address: request.remote_ip,
      params: permitted_params,
      user_agent: request.user_agent
    }.merge(keycard_attributes)
    log_entry.save
    Rails.logger.info "AUDIT LOG: #{obj.resource_type.to_s.camelize}, #{obj.id}, #{JSON.generate(log_entry.data)}"
  end
end
