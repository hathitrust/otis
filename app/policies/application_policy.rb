# frozen_string_literal: true

class ApplicationPolicy
  def can?(action, object, user)
    return false if object.nil?

    Checkpoint::Query::ActionPermitted.new(user, action,
      object.to_resource, authority: authority).true?
  end

  def authority
    Services.checkpoint
  end
end
