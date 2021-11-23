# frozen_string_literal: true

class HTApprovalRequestsPolicy < ApplicationPolicy
  def can?(action, object, user)
    super(action, object, user) || super(action, object.try(:ht_user), user)
  end
end
