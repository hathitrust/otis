# frozen_string_literal: true

class HTSSDProxyReportsController < ApplicationController
  def index
    reports = HTSSDProxyReport.order(:datetime)
    @reports = reports.map { |r| presenter r }
    @time_start = HTSSDProxyReport.minimum(:datetime).to_date.to_s
    @time_end = HTSSDProxyReport.maximum(:datetime).to_date.to_s
  end

  private

  def presenter(report)
    HTSSDProxyReportPresenter.new(report, controller: self, action: params[:action].to_sym)
  end
end
