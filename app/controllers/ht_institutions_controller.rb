# frozen_string_literal: true

class HTInstitutionsController < ApplicationController
  before_action :fetch_institution, only: %i[show edit update]

  PERMITTED_UPDATE_FIELDS = %i[
    grin_instance
    name
    domain
    entityID
    enabled
    allowed_affiliations
    shib_authncontext_class
    emergency_status
    mapto_inst_id
    mapto_name
    us
  ].freeze

  PERMITTED_CREATE_FIELDS = PERMITTED_UPDATE_FIELDS + %i[inst_id]

  def new
    @institution = HTInstitutionPresenter.new(HTInstitution.new)

    @institution.set_defaults_for_entity(params[:entityID]) if params[:entityID]
  end

  def index
    @enabled_institutions = HTInstitution.enabled.order('name').map { |i| HTInstitutionPresenter.new(i) }
    @other_institutions = HTInstitution.other.order('name').map { |i| HTInstitutionPresenter.new(i) }
  end

  def update
    if @institution.update(inst_params(PERMITTED_UPDATE_FIELDS))
      flash[:notice] = 'Institution updated'
      redirect_to @institution
    else
      flash.now[:alert] = @institution.errors.full_messages.to_sentence
      fetch_institution
      render :edit
    end
  end

  def create
    @institution = HTInstitutionPresenter.new(HTInstitution.new(inst_params(PERMITTED_CREATE_FIELDS)))

    if @institution.save
      redirect_to @institution, note: 'Institution was successfully created'
    else
      flash.now[:alert] = @institution.errors.full_messages.to_sentence
      render :new
    end
  end

  private

  def inst_params(permitted_fields)
    @inst_params ||= params.require(:ht_institution)
                           .permit(*permitted_fields)
                           .transform_values! { |v| v.present? ? v : nil }
  end

  def fetch_institution
    @institution = HTInstitutionPresenter.new(HTInstitution.find(params[:id]))
  end
end
