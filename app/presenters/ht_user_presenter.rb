# frozen_string_literal: true

class HTUserPresenter < ApplicationPresenter
  include ActionView::Helpers::DateHelper

  ALL_FIELDS = %i[
    email userid displayname activitycontact approver authorizer usertype
    role access expire_type expires renewal_status iprestrict mfa institution
  ].freeze

  INDEX_FIELDS = %i[email displayname role institution expires renewal_status iprestrict mfa].freeze
  HT_COUNTS_FIELDS = %i[accesses last_access].freeze
  READ_ONLY_FIELDS = (HT_COUNTS_FIELDS + %i[email renewal_status institution]).freeze
  FIELD_SIZE = 40

  def self.role_name(role)
    I18n.t role, scope: "ht_user.values.role", default: nil
  end

  def self.role_description(role)
    I18n.t role, scope: "ht_user.role_descriptions", default: nil
  end

  def ht_counts_fields
    self.class::HT_COUNTS_FIELDS
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

  def role_name
    HTUserPresenter.role_name role
  end

  def role_description
    HTUserPresenter.role_description role
  end

  # Override for MFA which may or may not be editable on the edit page.
  # Suppress the form if the field is :mfa and not editable.
  # The purpose of this is to prevent bogus HTML with a <label> that points
  # to nothing.
  def field_label(field, form: nil)
    form = nil if field == :mfa && !edit_mfa?
    super
  end

  private

  def show_accesses
    ht_count&.accesscount
  end

  def show_email
    (action == :index) ? email_link : email
  end

  def show_expires
    if action == :index
      fmt = I18n.l(self[:expires].to_date, format: :long) +
        "<p>#{expiration_badge}</p>"
      if expiring_soon?
        fmt += "<strong><span class=\"text-danger\">" +
          time_to_expiration + "</span></strong>"
      end
      fmt
    else
      I18n.l(self[:expires].to_date, format: :long) + "&nbsp;" + expiration_badge
    end
  end

  def show_institution
    return institution if ht_institution.nil?

    link_to institution, ht_institution_path(ht_institution.inst_id)
  end

  def show_iprestrict
    return "" unless iprestrict.present?
    if iprestrict == ["any"]
      return Otis::Badge.new("ht_user.values.iprestrict.any", "bg-success").label_span
    end

    iprestrict.to_sentence
  end

  def show_last_access
    date = ht_count&.last_access&.to_date
    date.present? ? I18n.l(date, format: :long) : ""
  end

  def show_mfa
    mfa ? <<~HTML : ""
      <span class="badge bg-success" aria-label="#{I18n.t("activerecord.attributes.ht_user.mfa")}">
      <i class="bi bi-lock-fill text-light" aria-hidden="true"></i>
      </span>
    HTML
  end

  def show_renewal_status
    renewal_status_badge
  end

  def select_for_renewal_checkbox_id
    "ht_users_#{email}"
  end

  def simple_email_link
    link_to email, ht_user_path(self)
  end

  def approval_request
    @approval_request ||= ht_approval_request.first
  end

  def renewal_status_badge
    return "" if approval_request.nil?

    HTApprovalRequestPresenter.new(approval_request)&.badge
  end

  def edit_access(form:)
    form.select(:access, access_options)
  end

  # NOTE: we do not use localized dates for this because the controller would
  # have to parse localized date formats when the value is edited.
  # There are two gems that may (or may not) be able to do this:
  # Chronic https://github.com/mojombo/chronic/
  # Delocalize https://github.com/clemens/delocalize
  # Both of these appear to be abandonware, so they have not been tried.
  # The calendar widget pushes most of the responsibility onto the browser
  # locale support and ensures we get consistent values.
  #
  # The buttons should maybe be pushed back out into edit.html.erb
  def edit_expires(form:)
    expires_class = expiring_soon? ? "bg-danger" : ""
    html = [form.date_field(:expires, value: expiration_date.to_s, class: expires_class)]
    unless expired?
      html << form.button(I18n.t("ht_user.edit.expire_now"), type: :button,
        onclick: "$('#ht_user_expires').val('#{Date.today}').addClass('bg-danger');".html_safe,
        class: "btn btn-primary")
    end
    new_expiration = expiration_date.default_extension_date
    html << form.button(I18n.t("ht_user.edit.renew_now"), type: :button,
      onclick: "$('#ht_user_expires').val('#{new_expiration}').removeClass('bg-danger');".html_safe,
      class: "btn btn-primary")
    html.join("\n")
  end

  def edit_expire_type(form:)
    form.select(:expire_type, expire_type_options)
  end

  def edit_iprestrict(form:)
    [form.text_field(:iprestrict, value: iprestrict&.join(", "), size: 40, disabled: mfa),
      "<p class='text-muted'>#{I18n.t("ht_user.edit.iprestrict_prompt")}</p>"].join("\n")
  end

  def edit_mfa?
    ht_institution.shib_authncontext_class.present?
  end

  def edit_mfa(form:)
    if edit_mfa?
      form.check_box(:mfa, onclick: "check_mfa();".html_safe)
    else
      Otis::Badge.new("ht_user.values.mfa.unavailable", "text-dark bg-warning").label_span
    end
  end

  def edit_role(form:)
    form.select(:role, role_options)
  end

  def edit_usertype(form:)
    form.select(:usertype, usertype_options)
  end

  def access_options
    @access_options ||= HTUser::ACCESSES.sort.map { |access| [I18n.t("ht_user.values.access.#{access}"), access] }
  end

  def expire_type_options
    @expiretype_options ||= ExpirationDate::EXPIRES_TYPE.keys.sort.map { |type| [I18n.t("ht_user.values.expire_type.#{type}"), type] }
  end

  def role_options
    @role_options ||= HTUser::ROLES.sort.map { |role| [I18n.t("ht_user.values.role.#{role}"), role] }
  end

  def usertype_options
    @usertype_options ||= HTUser::USERTYPES.sort.map { |type| [I18n.t("ht_user.values.usertype.#{type}"), type] }
  end

  def expiration_badge
    return Otis::Badge.new("ht_user.badges.expired", "bg-danger").label_span if expired?
    return Otis::Badge.new("ht_user.badges.expiring_soon", "text-dark bg-warning").label_span if expiring_soon?

    ""
  end

  def time_to_expiration
    distance_of_time_in_words_to_now(DateTime.now + days_until_expiration,
      include_seconds: false)
  end
end
