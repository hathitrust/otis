# frozen_string_literal: true

class HTInstitutionsController < ApplicationController
  before_action :fetch_institution, only: %i[show edit update]

  PERMITTED_UPDATE_FIELDS = %i[
    grin_instance
    name
    entityID
    enabled
    allowed_affiliations
    shib_authncontext_class
    emergency_status
    mapto_inst_id
    mapto_name
  ].freeze

  def index
    @enabled_institutions = HTInstitution.enabled.order('name').map { |i| HTInstitutionPresenter.new(i) }
    @other_institutions = HTInstitution.other.order('name').map { |i| HTInstitutionPresenter.new(i) }
  end

  def update
    if @institution.update(inst_params)
      flash[:notice] = 'Institution updated'
      redirect_to @institution
    else
      flash.now[:alert] = @institution.errors.full_messages.to_sentence
      fetch_institution
      render 'edit'
    end
  end

  private

  def inst_params
    @inst_params ||= params.require(:ht_institution)
      .permit(*PERMITTED_UPDATE_FIELDS)
      .transform_values!{|v| v.present? ? v : nil }
  end

  def fetch_institution
    @institution = HTInstitutionPresenter.new(HTInstitution.find(params[:id]))
  end
end
