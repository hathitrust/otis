# frozen_string_literal: true

class HTRegistrationsController < ApplicationController
  before_action :fetch_institutions

  PERMITTED_FIELDS = %i[
    applicant_name
    applicant_email
    applicant_date
    inst_id
    jira_ticket
    role
    expire_type
    contact_info
    auth_rep_name
    auth_rep_email
    auth_rep_date
    hathitrust_authorizer
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
    if Otis::RegistrationMover.user_exists? @registration
      flash.now[:alert] = t(".duplicate", email: @registration.applicant_email)
      render "new"
    elsif @registration.save
      log
      flash.now[:notice] = t(".success", name: @registration.applicant_name)
      redirect_to preview_ht_registration_path(@registration.id)
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
      flash[:notice] = t(".success", name: @registration.applicant_name)
      redirect_to action: :show
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "edit"
    end
  end

  def preview
    fetch_presenter
    @base_url = request.base_url
    @email_body = render_to_string(partial: "shared/registration_body")
      .gsub("__NAME__", @registration.applicant_name)
  end

  def mail
    fetch_registration
    send_mail
    redirect_to action: :show
  end

  def destroy
    fetch_registration
    log params.permit!
    @registration.destroy
    flash[:notice] = t(".success")
    redirect_to action: :index
  end

  # Create user from registration and redirect to its edit or show page
  def finish
    fetch_registration
    user = Otis::RegistrationMover.new(@registration).ht_user
    if user.valid?
      @registration.finished = Time.zone.now
      @registration.save!
      add_jira_comment template: :registration_finished
      log params.permit!
      redirect_to edit_ht_user_path user
    else
      flash[:alert] = user.errors.full_messages.to_sentence
      redirect_to @registration
    end
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
    RegistrationMailer.with(registration: @registration, base_url: request.base_url,
      body: params[:email_body], subject: params[:subject])
      .registration_email.deliver_now
    add_jira_comment template: :registration_sent
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

  # Adds comment from {:registration_sent, :registration_finished}
  def add_jira_comment(template:)
    comment = Otis::JiraClient.comment template: template, user: @registration.applicant_email
    Otis::JiraClient.new.comment! issue: @registration.jira_ticket, comment: comment
  end
end
