# frozen_string_literal: true

class HTInstitutionsController < ApplicationController
  before_action :fetch_institution, only: %i[show]

  def index
    @institutions = HTInstitution.order('name')
  end

  private

  def fetch_institution
    @institution = HTInstitution.find(params[:id])
  end
end
