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
    if @registration.save
      update_ea_ticket!
      log
      flash[:notice] = t(".success", name: @registration.applicant_name)
      redirect_to @registration
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
      update_ea_ticket!
      log
      flash[:notice] = t(".success", name: @registration.applicant_name)
      redirect_to action: :show
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "edit"
    end
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
    if @registration.finished?
      flash[:alert] = t(".already_finished")
      return redirect_to @registration
    end
    user = Otis::RegistrationMover.new(@registration).ht_user
    if user.valid?
      @registration.finished = Time.zone.now
      @registration.save!
      finish_ticket!
      log params.permit!
      flash[:notice] = t(".success", name: @registration.applicant_name)
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

  def update_ea_ticket!
    url = finalize_url(@registration.token, locale: nil)
    new_ticket = Otis::JiraClient::Registration.new(@registration, url).update_ea_ticket!
    # This is for debugging and system testing only
    unless Rails.env.production?
      flash[:alert] = "EA ticket: #{finalize_url @registration.token, locale: nil}"
    end
    @registration.sent = Time.zone.now
    @registration.save!
    flash[:info] = new_ticket ? "Created new ticket #{@registration.jira_ticket}" : "Updated ticket #{@registration.jira_ticket}"
  rescue => e
    flash[:alert] = e.message
  end

  # Do whatever needs to be done on the Jira side, generally this will send a final email and close.
  def finish_ticket!
    Otis::JiraClient::Registration.new(@registration).finish!
  rescue => e
    flash[:alert] = "Failure to communicate with Jira: " + e.message
  end
end
