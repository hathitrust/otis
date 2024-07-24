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
    @institution = presenter HTInstitution.new
    @institution.set_defaults_for_entity(params[:entityID]) if params[:entityID]
    @institution.ht_billing_member = HTBillingMember.new
  end

  def index
    @enabled_institutions = HTInstitution.enabled.order("name").map { |i| presenter i }
    @other_institutions = HTInstitution.other.order("name").map { |i| presenter i }
    respond_to do |format|
      format.html
      format.csv do
        file_name = (params[:file_name] || "ht_institutions") + ".csv"
        send_data institutions_csv, filename: file_name
      end
    end
  end

  def update
    @institution = HTInstitution.find(params[:id])

    if @institution.update(inst_params(PERMITTED_UPDATE_FIELDS))
      log
      flash[:notice] = t(".success")
      redirect_to presenter(@institution)
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
      flash[:notice] = t(".success")
      redirect_to presenter(@institution)
    else
      flash.now[:alert] = @institution.errors.full_messages.to_sentence
      @institution = presenter @institution
      render :new
    end
  end

  private

  def presenter(institution)
    HTInstitutionPresenter.new(institution, controller: self, action: params[:action].to_sym)
  end

  def log
    log_action(@institution, @inst_params)
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
    @institution = presenter HTInstitution.find(params[:id])
  end

  def institutions_csv
    require "csv"
    CSV.generate do |csv|
      csv << HTInstitution.column_names +
        HTBillingMember.column_names.map { |name| "billing_#{name}" }
      HTInstitution.order(:inst_id).each do |institution|
        billing_fields = institution&.ht_billing_member&.attributes&.values ||
          Array.new(HTBillingMember.column_names.count)
        csv << institution.attributes.values + billing_fields
      end
    end
  end
end
