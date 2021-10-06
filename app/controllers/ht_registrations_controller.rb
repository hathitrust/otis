# frozen_string_literal: true

class HTRegistrationsController < ApplicationController
  PERMITTED_CREATE_FIELDS = %i[
    inst_id
    name
    jira_ticket
    contact_info
    auth_rep_name
    auth_rep_email
    auth_rep_date
    dsp_name
    dsp_email
    dsp_date
    mfa_addendum
  ].freeze

  def new
    @registration = HTRegistration.new
  end

  def create
    @registration = HTRegistration.new(reg_params)
    if @registration.save
      redirect_to action: :index
    else
      redirect_to action: :error, msg: @registration.errors
    end
  end

  def index
    @all_registrations = HTRegistration.all
  end

  private

  def reg_params
    params.require(:ht_registration)
      .permit(*PERMITTED_CREATE_FIELDS)
      .transform_values! { |v| v.present? ? v : nil }
  end
end
