# frozen_string_literal: true

class HTSSDProxyReportsController < ApplicationController
  def index
    reports = HTSSDProxyReport.order(:datetime)
    @reports = reports.map { |r| presenter r }
  end

  private

  def presenter(report)
    HTSSDProxyReportPresenter.new(report, controller: self, action: params[:action].to_sym)
  end

  def report_params(permitted_fields)
    @report_params ||= params.require(:ht_ssd_proxy_report)
      .permit(*permitted_fields)
      .transform_values! { |v| v.present? ? v : nil }
  end
end
