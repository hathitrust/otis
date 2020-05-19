# frozen_string_literal: true

class HTUserPresenter < SimpleDelegator
  def init(user)
    @user = user
  end

  def badge
    HTApprovalRequestPresenter.badge_for(approval_request)
  end

  def renewed?
    approval_request&.renewed.present?
  end

  private

  def approval_request
    @approval_request ||= HTApprovalRequest.for_user(email).first
  end
end
