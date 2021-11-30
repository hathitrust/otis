# frozen_string_literal: true

class RegistrationsController < ApplicationController
  before_action :fetch_institutions

  PERMITTED_FIELDS = %i[
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
    @registration = RegistrationPresenter.new(Registration.new)
  end

  def index
    @all_registrations = Registration.all.map { |r|
      RegistrationPresenter.new(r)
    }
  end

  def create
    @registration = RegistrationPresenter.new(Registration.new(reg_params))
    if @registration.save
      log
      flash.now[:alert] = "Registration created for #{@registration.name}."
      redirect_to action: :index
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "new"
    end
  end

  def show
    fetch_presenter
  end

  def edit
    fetch_presenter
  end

  def update
    fetch_presenter

    if @registration.update(reg_params)
      log
      flash[:notice] = "Registration updated for #{@registration.name}"
      redirect_to action: :index
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "edit"
    end
  end

  def destroy
    @registration = Registration.find(params[:id])
    log params.permit!
    @registration.destroy
    flash[:notice] = "Registration deleted"
    redirect_to action: :index
  end

  private

  def reg_params
    params.require(:registration)
      .permit(*PERMITTED_FIELDS)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def fetch_registration
    @registration = Registration.find(params[:id])
  end

  def fetch_presenter
    @registration = RegistrationPresenter.new(fetch_registration)
  end

  def fetch_institutions
    @institutions = HTInstitution.all.sort
  end

  def log(params = reg_params)
    log_action(@registration, params)
  end
end
