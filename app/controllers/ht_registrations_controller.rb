# frozen_string_literal: true

class HTRegistrationsController < ApplicationController
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
    @registration = HTRegistration.new
    @institutions = HTInstitution.all.sort
  end

  def index
    @all_registrations = HTRegistration.all
  end
    
  def create
    @registration = HTRegistration.new(reg_params)
    @institutions = HTInstitution.all.sort
    if @registration.save
      flash.now[:alert] = "Registration created."
      redirect_to action: :index
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "new"
    end
  end

  def show
    @registration = HTRegistration.find(params[:id])
    @institutions = HTInstitution.all.sort
  end

  def update
    @registration = HTRegistration.find(params[:id])

    if @registration.update(reg_params)
      flash[:notice] = "Registration updated"
      redirect_to action: :index
    else
      flash.now[:alert] = @registration.errors.full_messages.to_sentence
      render "show"
    end
  end

  def destroy
    @registration = HTRegistration.find(params[:id])
    @registration.destroy
    flash[:notice] = "Registration deleted"
    redirect_to action: :index
  end

  # Maybe move to presenter?
  def jira_link(ticket)
    "https://tools.lib.umich.edu/jira/browse/#{ticket}"
  end
  
  private

  def reg_params
    params.require(:ht_registration)
      .permit(*PERMITTED_FIELDS)
      .transform_values! { |v| v.present? ? v : nil }
  end
end
