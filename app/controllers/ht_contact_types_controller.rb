# frozen_string_literal: true

class HTContactTypesController < ApplicationController
  before_action :fetch_contact_type, only: %i[destroy edit show]

  PERMITTED_UPDATE_FIELDS = %i[name description].freeze
  PERMITTED_CREATE_FIELDS = PERMITTED_UPDATE_FIELDS + %i[id]

  def new
    @contact_type = HTContactTypePresenter.new(HTContactType.new)
  end

  def index
    contact_types = HTContactType.order(:name)
    @contact_types = contact_types.map { |c| HTContactTypePresenter.new(c) }
  end

  def update
    @contact_type = HTContactType.find(params[:id])
    if @contact_type.update(contact_type_params(PERMITTED_UPDATE_FIELDS))
      flash[:notice] = "Contact type updated"
      redirect_to @contact_type
    else
      flash.now[:alert] = @contact_type.errors.full_messages.to_sentence
      fetch_contact_type
      render :edit
    end
  end

  def create
    @contact_type = HTContactType.new(contact_type_params(PERMITTED_CREATE_FIELDS))
    if @contact_type.save
      redirect_to @contact_type, note: "Contact type successfully created"
    else
      flash.now[:alert] = @contact_type.errors.full_messages.to_sentence
      @contact_type = HTContactTypePresenter.new(@contact_type)
      render :new
    end
  end

  def destroy
    if @contact_type.destroy
      flash[:notice] = "Contact type removed"
      redirect_to ht_contact_types_url
    else
      flash.now[:alert] = @contact_type.errors.full_messages.to_sentence
      render :show
    end
  end

  private

  def contact_type_params(permitted_fields)
    @contact_type_params ||= params.require(:ht_contact_type)
      .permit(*permitted_fields)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def fetch_contact_type
    @contact_type = HTContactTypePresenter.new(HTContactType.find(params[:id]))
  end
end
