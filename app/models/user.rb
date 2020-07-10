# frozen_string_literal: true

class User
  attr_accessor :id
  attr_writer :identity

  def self.authenticate_by_auth_token(_token)
    raise StandardError
  end

  def self.authenticate_by_id(id)
    User.new(id)
  end

  # Shib persistent ID, most likely
  def self.authenticate_by_user_eid(eid)
    User.new(eid)
  end

  def self.authenticate_by_user_pid(pid)
    User.new(pid)
  end

  def initialize(eid)
    @id = eid
  end

  def identity
    @identity ||= { username: id }.reject { |_, v| v.nil? }
  end

  def agent_id
    @id
  end

  def agent_type
    :user
  end
end
