# frozen_string_literal: true

class HTApprovalRequestBadge
  def initialize(tag, css_class)
    @css_class = css_class
    @tag = tag
  end

  def label_text
    I18n.t("ht_approval_request.badges.#{tag}")
  end

  def label_span
    "<span class='label #{css_class}'>#{label_text}</span>".html_safe
  end

  private

  attr_reader :css_class, :tag
end

class HTApprovalRequestPresenter < SimpleDelegator
  include ActionView::Helpers::FormTagHelper
  include Rails.application.routes.url_helpers

  BADGES = {
    approved: HTApprovalRequestBadge.new("approved", "label-info"),
    expired: HTApprovalRequestBadge.new("expired", "label-danger"),
    renewed: HTApprovalRequestBadge.new("renewed", "label-success"),
    sent: HTApprovalRequestBadge.new("sent", "label-default"),
    unsent: HTApprovalRequestBadge.new("unsent", "label-warning")
  }.freeze

  def init(request)
    @request = request
  end

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

  def controller
    # required for url helpers to work
  end
end
