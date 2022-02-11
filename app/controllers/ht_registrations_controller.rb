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
    @registration = presenter HTRegistration.new
  end

  def index
    @all_registrations = HTRegistration.all.map { |r| presenter r }
  end

  def create
    @registration = presenter HTRegistration.new(reg_params)
    if @registration.save
      log
      flash.now[:notice] = t(".success", name: @registration.dsp_name)
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
      flash[:notice] = t(".success", name: @registration.dsp_name)
      redirect_to action: :index
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "edit"
    end
  end

  def preview
    fetch_presenter
    @finalize_url = finalize_url @registration.token, locale: nil
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
    flash[:notice] = t(".success")
    redirect_to action: :index
  end

  private

  def reg_params
    params.require(:ht_registration)
      .permit(*PERMITTED_FIELDS)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def presenter(registration)
    HTRegistrationPresenter.new(registration, controller: self,
      action: params[:action].to_sym)
  end

  def fetch_registration
    @registration = HTRegistration.find(params[:id])
  end

  def fetch_presenter
    @registration = presenter fetch_registration
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
    flash[:notice] = t("ht_registrations.mail.success")
    # This is for debugging only
    if Rails.env.development?
      flash[:notice] = "Message sent: #{finalize_url @registration.token, locale: nil}"
    end
    log params.transform_values! { |v| v.present? ? v : nil }.permit!
    @registration.sent = Time.zone.now
    @registration.save!
  rescue => e
    flash[:alert] = e.message
  end
end
