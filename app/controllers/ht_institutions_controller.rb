# frozen_string_literal: true

class HTInstitutionsController < ApplicationController
  before_action :fetch_institution, only: %i[show edit]

  PERMITTED_UPDATE_FIELDS = %i[
    grin_instance
    name
    domain
    entityID
    enabled
    allowed_affiliations
    shib_authncontext_class
    emergency_status
    emergency_contact
    mapto_inst_id
    mapto_name
    us
  ].freeze

  PERMITTED_BILLING_FIELDS = %i[
    weight
    oclc_sym
    marc21_sym
    country_code
    status
  ].freeze

  PERMITTED_CREATE_FIELDS = PERMITTED_UPDATE_FIELDS + %i[inst_id]

  def new
    @institution = HTInstitutionPresenter.new(HTInstitution.new)

    @institution.set_defaults_for_entity(params[:entityID]) if params[:entityID]
    @institution.ht_billing_member = HTBillingMember.new
  end

  def index
    @enabled_institutions = HTInstitution.enabled.order("name").map { |i| HTInstitutionPresenter.new(i) }
    @other_institutions = HTInstitution.other.order("name").map { |i| HTInstitutionPresenter.new(i) }
  end

  def update
    @institution = HTInstitution.find(params[:id])

    if @institution.update(inst_params(PERMITTED_UPDATE_FIELDS))
      log
      flash[:notice] = "Institution updated"
      redirect_to @institution
    else
      flash.now[:alert] = @institution.errors.full_messages.to_sentence
      fetch_institution
      render :edit
    end
  end

  def create
    @institution = HTInstitution.new(inst_params(PERMITTED_CREATE_FIELDS))

    if @institution.save
      log
      redirect_to @institution, note: "Institution was successfully created"
    else
      flash.now[:alert] = @institution.errors.full_messages.to_sentence
      @institution = HTInstitutionPresenter.new(@institution)
      render :new
    end
  end

  private

  def log
    log_action(HTInstitutionLog.new(ht_institution: @institution), @inst_params)
  end

  def inst_params(permitted_fields)
    @inst_params ||= params.require(:ht_institution)
      .permit(*permitted_fields)
      .merge(billing_member_params)
      .transform_values! { |v| v.present? ? v : nil }
  end

  def billing_member_params
    return unless use_billing_params && params[:ht_institution][:ht_billing_member_attributes]

    {ht_billing_member_attributes:
      params
        .require(:ht_institution)
        .require(:ht_billing_member_attributes)
        .permit(PERMITTED_BILLING_FIELDS)
        .transform_values! { |v| v.present? ? v : nil }}
  end

  def use_billing_params
    params[:create_billing_member] || @institution&.ht_billing_member
  end

  def fetch_institution
    @institution = HTInstitutionPresenter.new(HTInstitution.find(params[:id]))
  end
end
