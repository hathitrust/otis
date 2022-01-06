# frozen_string_literal: true

class HTRegistrationPresenter < ApplicationPresenter
  ALL_FIELDS = %i[
    name inst_id jira_ticket contact_info auth_rep_name auth_rep_email auth_rep_date
    dsp_name dsp_email dsp_date mfa_addendum
  ].freeze

  INDEX_FIELDS = %i[name inst_id jira_ticket contact_info auth_rep dsp mfa_addendum].freeze
  JIRA_BASE_URL = "https://tools.lib.umich.edu/jira/browse"
  FIELD_SIZE = 45

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

  def show_jira_ticket
    link_to jira_ticket, "#{self.class::JIRA_BASE_URL}/#{jira_ticket}"
  end

  def show_inst_id
    link_to inst_id, ht_institution_path(inst_id)
  end

  def show_mfa_addendum
    mfa_addendum ? "<span class='label label-success'><i class='glyphicon glyphicon-lock'></i></span>" : ""
  end

  def show_name
    action == :index ? link_to(name, ht_registration_path(id)) : name
  end

  # See comments about localization and date entry in ht_user_presenter.rb
  def edit_auth_rep_date(form:)
    form.date_field :auth_rep_date, value: auth_rep_date.to_s
  end

  def edit_dsp_date(form:)
    form.date_field :dsp_date, value: dsp_date.to_s
  end

  def edit_inst_id(form:)
    form.collection_select(:inst_id, HTInstitution.enabled.all, :inst_id, :name)
  end

  def edit_mfa_addendum(form:)
    form.check_box :mfa_addendum
  end
end
