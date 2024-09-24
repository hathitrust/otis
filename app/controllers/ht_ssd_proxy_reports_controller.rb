# frozen_string_literal: true

class HTSSDProxyReportsController < ApplicationController
  RANSACK_MATCHERS = {
    "author" => :ht_hathifile_author_i_cont,
    "bib_num" => :ht_hathifile_bib_num_cont,
    "content_provider_code" => :ht_hathifile_content_provider_code_eq,
    "datetime" => :datetime_start,
    "digitization_agent_code" => :ht_hathifile_digitization_agent_code,
    "email" => :email_i_cont,
    "htid" => :htid_i_cont,
    "imprint" => :ht_hathifile_imprint_i_cont,
    "inst_code" => :inst_code_eq,
    "institution_name" => :ht_institution_name_i_cont,
    "rights_code" => :ht_hathifile_rights_code_eq,
    "rights_date_used" => :ht_hathifile_rights_date_used_eq,
    "title" => :ht_hathifile_title_i_cont
  }

  RANSACK_ORDER = {
    "author" => :ht_hathifile_author,
    "bib_num" => :ht_hathifile_bib_num,
    "content_provider_code" => :ht_hathifile_content_provider_code,
    "datetime" => :datetime,
    "digitization_agent_code" => :ht_hathifile_digitization_agent_code,
    "email" => :email,
    "htid" => :htid,
    "imprint" => :ht_hathifile_imprint,
    "inst_code" => :inst_code,
    "institution_name" => :ht_institution_name,
    "rights_code" => :ht_hathifile_rights_code,
    "rights_date_used" => :ht_hathifile_rights_date_used,
    "title" => :ht_hathifile_title
  }

  def index
    respond_to do |format|
      format.html do
        # Populate the date range fields with the latest datetime and
        # then the start date a year earlier
        @time_end = HTSSDProxyReport.maximum(:datetime).tap do |time_end|
          @time_start = (time_end - 1.year).to_date.to_s
        end.to_date.to_s
      end
      format.json do
        render json: json_query
      end
    end
  end

  private

  def presenter(report)
    HTSSDProxyReportPresenter.new(report, controller: self, action: params[:action].to_sym)
  end

  def json_query
    search = HTSSDProxyReport.includes(:ht_hathifile, :ht_institution)
      .ransack(matchers)
    sort_name = RANSACK_ORDER.fetch(params[:sortName], "datetime")
    sort_order = params.fetch(:sortOrder, "asc")
    # Ransack requires lower case sort direction.
    search.sorts = "#{sort_name} #{sort_order.downcase}"
    result = search.result
    total = result.count
    if params[:pageNumber] && params[:pageSize]
      result = result.page(params[:pageNumber]).per(params[:pageSize])
    end
    {
      total: total,
      totalNotFiltered: HTSSDProxyReport.count,
      rows: result.map { |line| line_to_json line }
    }
  end

  # Use presenter to translate HTSSDProxyReport into JSON hash
  def line_to_json(report)
    report = presenter report
    HTSSDProxyReportPresenter::ALL_FIELDS.to_h do |field|
      [field, report.field_value(field)]
    end
  end

  # Filter param sent by Bootstrap Table translated into Hash
  def filter
    @filter ||= JSON.parse(params.fetch("filter", "{}"))
  end

  # Translate Bootstrap Table filter fields and date start/end fields
  # into Ransack matchers
  def matchers
    return @matchers if @matchers

    @matchers = filter.transform_keys do |key|
      RANSACK_MATCHERS.fetch(key, key)
    end
    if params[:d1]
      @matchers[:datetime_gteq] = params[:d1]
    end
    if params[:d2]
      @matchers[:datetime_lteq] = params[:d2]
    end
    @matchers
  end
end
