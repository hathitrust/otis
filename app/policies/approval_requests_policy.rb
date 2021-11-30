# frozen_string_literal: true

class ApprovalRequestsPolicy < ApplicationPolicy
  def can?(action, object, user)
    super(action, object, user) || super(action, object.try(:ht_user), user)
  end
end
