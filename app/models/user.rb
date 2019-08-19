# frozen_string_literal: true

class User
  attr_accessor :id
  attr_writer :identity

  def self.find_by_username(username)
    @valid_users ||= Ettin.for(Ettin.settings_files('config', Rails.env))[:users]
    raise ApplicationController::NotAuthorizedError unless @valid_users.include? username

    User.new(username)
  end

  def self.authenticate_by_auth_token(_token)
    raise UnimplementedError
  end

  def self.authenticate_by_id(id)
    Rails.logger.debug("[AUTH] id #{id}")
    User.new(id)
  end

  # Shib persistent ID, most likely
  def self.authenticate_by_user_eid(eid)
    User.new(eid)
  end

  def initialize(eid)
    @id = eid
  end

  def identity
    @identity ||= { username: id }.reject { |_, v| v.nil? }
  end
end
