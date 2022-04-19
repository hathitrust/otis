# frozen_string_literal: true

require "resolv"

class HTRegistrationPresenter < ApplicationPresenter
  ALL_FIELDS = %i[
    applicant_name applicant_email applicant_date inst_id jira_ticket
    role expire_type auth_rep_name auth_rep_email auth_rep_date
    contact_info hathitrust_authorizer mfa_addendum
    sent received finished ip_address
  ].freeze

  DETAIL_FIELDS = %i[
    detail_edu_person_principal_name detail_display_name detail_email
    detail_scoped_affiliation detail_identity_provider detail_geoip detail_reverse_lookup
  ].freeze

  INDEX_FIELDS = %i[applicant inst_id jira_ticket auth_rep mfa_addendum status].freeze
  READ_ONLY_FIELDS = %i[sent received finished ip_address env].freeze
  JIRA_BASE_URL = URI.join(Otis.config.jira.site, "/jira/", "browse/").to_s.freeze
  FIELD_SIZE = 45

  BADGES = {
    sent: Otis::Badge.new("activerecord.attributes.ht_registration.sent", "label-info"),
    received: Otis::Badge.new("activerecord.attributes.ht_registration.received", "label-default"),
    finished: Otis::Badge.new("activerecord.attributes.ht_registration.finished", "label-success"),
    institution_static_ip: Otis::Badge.new("activerecord.attributes.ht_registration.institution.static_ip", "label-danger"),
    institution_mfa: Otis::Badge.new("activerecord.attributes.ht_registration.institution.mfa", "label-success")
  }.freeze

  def detail_fields
    self.class::DETAIL_FIELDS
  end

  private

  def show_auth_rep
    [auth_rep_name, show_auth_rep_email, show_auth_rep_date].join "<br/>"
  end

  def show_auth_rep_date
    return "" unless auth_rep_date.present?

    I18n.l auth_rep_date.to_date, format: :long
  end

  def show_auth_rep_email
    link_to auth_rep_email, "mailto:#{auth_rep_email}"
  end

  def show_applicant
    [link_to(applicant_name, ht_registration_path(id)),
      applicant_email,
      show_applicant_date].join "<br/>"
  end

  def show_applicant_date
    return "" unless applicant_date.present?

    I18n.l applicant_date.to_date, format: :long
  end

  def show_applicant_email
    link_to applicant_email, "mailto:#{applicant_email}"
  end

  def show_detail_display_name
    env["HTTP_X_SHIB_DISPLAYNAME"]
  end

  def show_detail_edu_person_principal_name
    env["HTTP_X_SHIB_EDUPERSONPRINCIPALNAME"]
  end

  def show_detail_email
    env["HTTP_X_SHIB_MAIL"]
  end

  def show_detail_geoip
    geoip = Services.geoip.city ip_address
    [geoip.country.name, geoip.most_specific_subdivision.name, geoip.city.name].join(" — ")
  rescue => _e
    ""
  end

  def show_detail_identity_provider
    entity = env["HTTP_X_SHIB_IDENTITY_PROVIDER"]
    ERB::Util.html_escape(HTInstitution.where(entityID: entity).first&.name || entity)
  end

  def show_detail_reverse_lookup
    Resolv.getname ip_address
  rescue Resolv::ResolvError => _e
    Otis::Badge.new("errors.resolv", "label-danger", ip_address: ip_address).label_span
  end

  def show_detail_scoped_affiliation
    env["HTTP_X_SHIB_EDUPERSONSCOPEDAFFILIATION"]
  end

  def show_finished
    return "" unless finished.present?

    I18n.l finished.to_date, format: :long
  end

  def show_jira_ticket
    link_to jira_ticket, self.class::JIRA_BASE_URL + jira_ticket
  end

  def show_inst_id
    link_to(ht_institution.name, ht_institution_path(inst_id)) + " " +
      (ht_institution.mfa? ? BADGES[:institution_mfa] : BADGES[:institution_static_ip]).label_span
  end

  def show_mfa_addendum
    mfa_addendum ? "<span class='label label-success'><i class='glyphicon glyphicon-lock'></i></span>" : ""
  end

  def show_received
    return "" unless received.present?

    I18n.l received.to_date, format: :long
  end

  def show_sent
    return "" unless sent.present?

    I18n.l sent.to_date, format: :long
  end

  def show_status
    return BADGES[:finished].label_span if finished?
    return BADGES[:received].label_span if received?
    return BADGES[:sent].label_span if sent?
  end

  # See comments about localization and date entry in ht_user_presenter.rb
  def edit_auth_rep_date(form:)
    form.date_field :auth_rep_date, value: auth_rep_date.to_s
  end

  def edit_applicant_date(form:)
    form.date_field :applicant_date, value: applicant_date.to_s
  end

  def edit_expire_type(form:)
    form.select(:expire_type, expire_type_options)
  end

  def edit_inst_id(form:)
    form.collection_select(:inst_id, HTInstitution.enabled.all, :inst_id, :name,
      {}, {class: "select-institution"})
  end

  def edit_mfa_addendum(form:)
    form.check_box :mfa_addendum
  end

  def edit_role(form:)
    form.select(:role, role_options)
  end

  def expire_type_options
    @expiretype_options ||= ExpirationDate::EXPIRES_TYPE.keys.sort.map { |type| [I18n.t("ht_user.values.expire_type.#{type}"), type] }
  end

  def role_options
    @role_options ||= HTRegistration::ROLES.sort.map { |role| [I18n.t("ht_registration.values.role.#{role}"), role] }
  end
end
