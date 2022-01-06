# frozen_string_literal: true

class HTApprovalRequestPresenter < ApplicationPresenter
  # Currently unused
  ALL_FIELDS = %i[approver user sent approved renewed]
  INDEX_FIELDS = %i[approver user sent approved renewed]

  BADGES = {
    approved: Otis::Badge.new("ht_approval_request.badges.approved", "label-success"),
    expired: Otis::Badge.new("ht_approval_request.badges.expired", "label-danger"),
    sent: Otis::Badge.new("ht_approval_request.badges.sent", "label-default"),
    unsent: Otis::Badge.new("ht_approval_request.badges.unsent", "label-warning")
  }.freeze

  def badge
    BADGES[renewal_state]&.label_span
  end

  def select_for_renewal_checkbox
    if show_index_checkbox?
      check_box_tag "ht_users[]", userid, false, id: select_for_renewal_checkbox_id
    else
      ""
    end
  end

  def userid_link(label: false)
    if label && show_index_checkbox?
      label_tag approver, simple_userid_link, for: select_for_renewal_checkbox_id
    else
      simple_userid_link
    end
  end

  def approver_link
    link_to approver, edit_ht_approval_request_path(approver)
  end

  private

  def show_index_checkbox?
    received.present? && renewed.nil?
  end

  def select_for_renewal_checkbox_id
    "req_#{userid}_#{approver}"
  end

  def simple_userid_link
    link_to userid, ht_user_path(userid)
  end
end
