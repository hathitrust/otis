# frozen_string_literal: true

class HTContactsController < ApplicationController
  before_action :fetch_contact, only: %i[destroy edit show]

  PERMITTED_UPDATE_FIELDS = %i[inst_id contact_type email].freeze
  PERMITTED_CREATE_FIELDS = PERMITTED_UPDATE_FIELDS + %i[id]

  def new
    @contact = HTContactPresenter.new(HTContact.new)
  end

  def index
    contacts = HTContact.includes(:ht_institution).order("ht_institutions.name")
    @contacts = contacts.map { |c| HTContactPresenter.new(c) }
  end

  def update
    @contact = HTContact.find(params[:id])
    if @contact.update(contact_params(PERMITTED_UPDATE_FIELDS))
      log
      flash[:notice] = "Contact updated"
      redirect_to @contact
    else
      flash.now[:alert] = @contact.errors.full_messages.to_sentence
      fetch_contact
      render :edit
    end
  end

  def create
    @contact = HTContact.new(contact_params(PERMITTED_CREATE_FIELDS))
    if @contact.save
      log
      redirect_to @contact, note: "Contact #{@contact.email} created"
    else
      flash.now[:alert] = @contact.errors.full_messages.to_sentence
      @contact = HTContactPresenter.new(@contact)
      render :new
    end
  end

  def destroy
    # Log here, because after #destroy the object becomes invalid
    log params.permit!
    if @contact.destroy
      flash[:notice] = "contact removed"
      redirect_to ht_contacts_url
    else
      flash.now[:alert] = @contact.errors.full_messages.to_sentence
      render :show
    end
  end

  private

  def log(params = @contact_params)
    log_action(@contact, params)
  end

  def contact_params(permitted_fields)
    @contact_params ||= params.require(:ht_contact)
      .permit(*permitted_fields)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def fetch_contact
    @contact = HTContactPresenter.new(HTContact.find(params[:id]))
  end
end
