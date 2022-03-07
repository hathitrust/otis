# frozen_string_literal: true

class HTRegistrationPresenter < ApplicationPresenter
  ALL_FIELDS = %i[
    dsp_name dsp_email dsp_date inst_id jira_ticket
    auth_rep_name auth_rep_email auth_rep_date
    contact_info mfa_addendum sent received finished ip_address env
  ].freeze

  INDEX_FIELDS = %i[dsp_name dsp inst_id jira_ticket auth_rep mfa_addendum status].freeze
  READ_ONLY_FIELDS = %i[sent received finished ip_address env].freeze
  JIRA_BASE_URL = "https://tools.lib.umich.edu/jira/browse"
  FIELD_SIZE = 45

  BADGES = {
    sent: Otis::Badge.new("activerecord.attributes.ht_registration.sent", "label-info"),
    received: Otis::Badge.new("activerecord.attributes.ht_registration.received", "label-default"),
    finished: Otis::Badge.new("activerecord.attributes.ht_registration.finished", "label-success")
  }.freeze

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

  def show_dsp
    [dsp_name, show_dsp_email, show_dsp_date].join "<br/>"
  end

  def show_dsp_date
    return "" unless dsp_date.present?

    I18n.l dsp_date.to_date, format: :long
  end

  def show_dsp_email
    link_to dsp_email, "mailto:#{dsp_email}"
  end

  def show_dsp_name
    action == :index ? link_to(dsp_name, ht_registration_path(id)) : dsp_name
  end

  def show_env
    return unless self[:env].present?

    fields = JSON.parse self[:env]
    return unless fields.any?

    ["<pre>", fields.map { |k, v| "<strong>#{k}</strong> #{v}" }, "</pre>"].join "\n"
  end

  def show_finished
    return "" unless finished.present?

    I18n.l finished.to_date, format: :long
  end

  def show_jira_ticket
    link_to jira_ticket, "#{self.class::JIRA_BASE_URL}/#{jira_ticket}"
  end

  def show_inst_id
    link_to ht_institution.name, ht_institution_path(inst_id)
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

  def edit_dsp_date(form:)
    form.date_field :dsp_date, value: dsp_date.to_s
  end

  def edit_inst_id(form:)
    form.collection_select(:inst_id, HTInstitution.enabled.all, :inst_id, :name,
      {}, {class: "select-institution"})
  end

  def edit_mfa_addendum(form:)
    form.check_box :mfa_addendum
  end
end
