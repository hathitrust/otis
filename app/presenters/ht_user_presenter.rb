# frozen_string_literal: true

class HTUserPresenter < SimpleDelegator
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def init(user)
    @user = user
  end

  def badge
    return "" if approval_request.nil?

    HTApprovalRequestPresenter.new(approval_request)&.badge
  end

  def can_renew?
    approval_request&.received.present? && !approval_request&.renewed.present?
  end

  def can_request?
    approval_request.nil? || approval_request.renewed.present?
  end

  def select_for_renewal_checkbox
    if (can_request? || can_renew?) && !expired?
      check_box_tag "ht_users[]", email, false, id: select_for_renewal_checkbox_id
    else
      ""
    end
  end

  def email_link
    if (can_request? || can_renew?) && !expired?
      # Redundantly specify the for= attribute so it doesn't get escaped
      label_tag :blah, simple_email_link, for: select_for_renewal_checkbox_id
    else
      simple_email_link
    end
  end

  def mfa_icon
    checkmark_icon(mfa)
  end

  # MFA checkbox and label would be simpler if we could just use the edit page
  # ActionView::Helpers::FormHelper form, alas it complicates testing.
  def mfa_label
    if ht_institution.shib_authncontext_class.present?
      label_tag :mfa_checkbox, "Multi-Factor?:"
    else
      "Multi-Factor?:"
    end
  end

  def mfa_checkbox
    if ht_institution.shib_authncontext_class.present?
      raw [hidden_field_tag("ht_user[mfa]", 0),
        check_box_tag("ht_user[mfa]", 1, mfa.present?, id: :mfa_checkbox,
                                                       onclick: "check_mfa();")].join "\n"
    else
      "Not Available"
    end
  end

  private

  def select_for_renewal_checkbox_id
    "ht_users_#{email}"
  end

  def simple_email_link
    link_to email, ht_user_path(self)
  end

  def approval_request
    @approval_request ||= HTApprovalRequest.most_recent(email).first
  end

  def checkmark_icon(field)
    raw field ? '<i class="glyphicon glyphicon-ok"></i>' : ""
  end

  def controller
    # required for url helpers to work
  end
end
