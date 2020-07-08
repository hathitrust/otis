# frozen_string_literal: true

class HTApprovalRequestPresenter
  def self.badge_for(obj)
    @badges ||= {
      approved: "<span class='label label-info'>#{I18n.t('ht_approval_request.badges.approved')}</span>",
      expired: "<span class='label label-danger'>#{I18n.t('ht_approval_request.badges.expired')}</span>",
      renewed: "<span class='label label-success'>#{I18n.t('ht_approval_request.badges.renewed')}</span>",
      sent: "<span class='label label-default'>#{I18n.t('ht_approval_request.badges.sent')}</span>",
      unsent: "<span class='label label-warning'>#{I18n.t('ht_approval_request.badges.unsent')}</span>"
    }
    return '' if obj.nil?

    @badges[obj.renewal_state]&.html_safe
  end
end
