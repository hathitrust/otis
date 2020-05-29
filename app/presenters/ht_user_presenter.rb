# frozen_string_literal: true

class HTUserPresenter < SimpleDelegator
  def init(user)
    @user = user
  end

  def badge
    HTApprovalRequestPresenter.badge_for(approval_request)
  end

  def can_renew?
    approval_request&.received.present? && !approval_request&.renewed.present?
  end

  def can_request?
    approval_request.nil?
  end

  private

  def approval_request
    @approval_request ||= HTApprovalRequest.for_user(email).first
  end
end
