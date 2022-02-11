# frozen_string_literal: true

class HTContactsController < ApplicationController
  before_action :fetch_contact, only: %i[destroy edit show]

  PERMITTED_UPDATE_FIELDS = %i[inst_id contact_type email].freeze
  PERMITTED_CREATE_FIELDS = PERMITTED_UPDATE_FIELDS + %i[id]

  def new
    @contact = presenter HTContact.new
  end

  def index
    @contacts = HTContact.includes(:ht_institution)
      .order("ht_institutions.name")
      .map { |c| presenter c }
    respond_to do |format|
      format.html
      format.csv do
        send_data contacts_csv,
          type: "text/csv; charset=utf-8; header=present",
          disposition: "attachment; filename=ht_contacts.csv"
      end
    end
  end

  def update
    @contact = HTContact.find(params[:id])
    if @contact.update(contact_params(PERMITTED_UPDATE_FIELDS))
      log
      flash[:notice] = t ".success"
      redirect_to presenter(@contact)
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
      flash[:notice] = t ".success"
      redirect_to presenter(@contact)
    else
      flash.now[:alert] = @contact.errors.full_messages.to_sentence
      @contact = presenter @contact
      render :new
    end
  end

  def destroy
    # Log here, because after #destroy the object becomes invalid
    log params.permit!
    if @contact.destroy
      flash[:notice] = t ".success"
      redirect_to ht_contacts_url
    else
      # Don't know how to trigger this for testing without dynamic patching.
      flash.now[:alert] = @contact.errors.full_messages.to_sentence
      render :show
    end
  end

  private

  def presenter(contact)
    HTContactPresenter.new(contact, controller: self, action: params[:action].to_sym)
  end

  def log(params = @contact_params)
    log_action(@contact, params)
  end

  def contact_params(permitted_fields)
    @contact_params ||= params.require(:ht_contact)
      .permit(*permitted_fields)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def fetch_contact
    @contact = presenter HTContact.find(params[:id])
  end

  def contacts_csv
    require "csv"
    CSV.generate do |csv|
      csv << %i[ID Institution Type E-mail]
      @contacts.each do |contact|
        csv << [contact.id, contact.ht_institution.name,
          contact.ht_contact_type.name, contact.email]
      end
    end
  end
end
