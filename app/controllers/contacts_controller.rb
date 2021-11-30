# frozen_string_literal: true

class ContactsController < ApplicationController
  before_action :fetch_contact, only: %i[destroy edit show]

  PERMITTED_UPDATE_FIELDS = %i[inst_id contact_type email].freeze
  PERMITTED_CREATE_FIELDS = PERMITTED_UPDATE_FIELDS + %i[id]

  def new
    @contact = ContactPresenter.new(Contact.new)
  end

  def index
    contacts = if params[:contact_type].blank?
      Contact.includes(:ht_institution).order("ht_institutions.name")
    else
      Contact.where(contact_type: params[:contact_type])
    end
    @contacts = contacts.map { |c| ContactPresenter.new(c) }
    respond_to do |format|
      format.html
      format.csv do
        send_data contacts_csv,
          type: "text/csv; charset=utf-8; header=present",
          disposition: "attachment; filename=contacts.csv"
      end
    end
  end

  def update
    @contact = Contact.find(params[:id])
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
    @contact = Contact.new(contact_params(PERMITTED_CREATE_FIELDS))
    if @contact.save
      log
      redirect_to @contact, note: "Contact #{@contact.email} created"
    else
      flash.now[:alert] = @contact.errors.full_messages.to_sentence
      @contact = ContactPresenter.new(@contact)
      render :new
    end
  end

  def destroy
    # Log here, because after #destroy the object becomes invalid
    log params.permit!
    if @contact.destroy
      flash[:notice] = "contact removed"
      redirect_to contacts_url
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
    @contact_params ||= params.require(:contact)
      .permit(*permitted_fields)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def fetch_contact
    @contact = ContactPresenter.new(Contact.find(params[:id]))
  end

  def contacts_csv
    require "csv"
    CSV.generate do |csv|
      csv << %i[ID Institution Type E-mail]
      @contacts.each do |contact|
        csv << [contact.id, contact.ht_institution.name,
          contact.contact_type.name, contact.email]
      end
    end
  end
end
