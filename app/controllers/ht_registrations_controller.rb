# frozen_string_literal: true

class HTRegistrationsController < ApplicationController
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
    @registration = HTRegistrationPresenter.new(HTRegistration.new)
  end

  def index
    @all_registrations = HTRegistration.all.map { |r|
      HTRegistrationPresenter.new(r)
    }
  end

  def create
    @registration = HTRegistrationPresenter.new(HTRegistration.new(reg_params))
    if @registration.save
      log
      flash.now[:alert] = "Registration created for #{@registration.dsp_name}."
      redirect_to preview_ht_registration_path(@registration)
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
      flash[:notice] = "Registration updated for #{@registration.dsp_name}"
      redirect_to action: :index
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "edit"
    end
  end

  def preview
    fetch_presenter
    @finalize_url = finalize_url @registration.token
    @email_body = render_to_string partial: "shared/registration_body"
  end

  def mail
    fetch_registration
    send_mail
    redirect_to action: :show
  end

  def destroy
    @registration = HTRegistration.find(params[:id])
    log params.permit!
    @registration.destroy
    flash[:notice] = "Registration deleted"
    redirect_to action: :index
  end

  private

  def reg_params
    params.require(:ht_registration)
      .permit(*PERMITTED_FIELDS)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def fetch_registration
    @registration = HTRegistration.find(params[:id])
  end

  def fetch_presenter
    @registration = HTRegistrationPresenter.new(fetch_registration)
  end

  def fetch_institutions
    @institutions = HTInstitution.all.sort
  end

  def log(params = reg_params)
    log_action(@registration, params)
  end

  def send_mail
    RegistrationMailer.with(registration: @registration,
      finalize_url: finalize_url(@registration.token, host: request.base_url),
      body: params[:email_body]).registration_email.deliver_now
    flash[:notice] = "Message sent"
    log params.transform_values! { |v| v.present? ? v : nil }.permit!
    @registration.sent = Time.zone.now
    @registration.save!
  rescue => e
    flash[:alert] = e.message
  end
end
