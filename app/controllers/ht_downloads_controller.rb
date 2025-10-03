# frozen_string_literal: true

class HTDownloadsController < ApplicationController
  # This class is only responsible for an index page. There are no detail views or editing
  # capabilities.
  # Bootstrap Table gets all its data server-side, so most of the plumbing in this class
  # is in support of `format=json` queries.

  # Extensive use is made of Ransack (https://github.com/activerecord-hackery/ransack)
  # which I chose because assembling LIKE queries in this controller appeared likely to
  # become a rabbit hole.

  # Pagination is provided by Kaminari. See the `results.page(...).per(...)` calls.

  # This is what a JSON request looks like when it comes in from Bootstrap Table:
  # ?format=json&pageSize=10&pageNumber=1&filter={"rights_code":"pdus"}&dateStart=2023-09-19&dateEnd=2024-09-19&sortName=inst_code&sortOrder=asc
  # - dateStart and dateEnd are the two date ranges initially populated by @date_start and @date_end
  # - sortName and sortOrder, if present, reflect the user's interaction with the column sort controls.
  # - filter={...} reflects the filters selected or typed into the column filters in the table.

  # The `filter` keys come from HTDownloadPresenter::ALL_FIELDS which combines relevant
  # columns from the three associated database tables.

  # Used by `#matchers` to translate `filter` keys into values that the `#ransack` method
  # can apply to the Active Record query. Many of these (the text input ones)
  # are of the form `*_i_cont` which is a case-insensitive contains equivalent to "LIKE '%value%'".
  # Those selectable by a dropdown menu can use an equality (`_eq`)  matcher.
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

  # Translation table from params[:sortName] to a form Ransack can understand.
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
        @date_end = HTDownload.maximum(:datetime).tap do |dt_end|
          @date_start = (dt_end - 1.year).to_date.to_s
        end.to_date.to_s
      end
      format.json do
        render json: json_query
      end
    end
  end

  private

  # @return [Hash] value to be returned to Bootstrap Table as JSON
  def json_query
    # Create a Ransack::Search with all of the filter fields translated into Ransack matchers.
    search = HTDownload.includes(:ht_hathifile, :ht_institution)
      .ransack(matchers)
    # Apply the sort field and order, or default if not provided.
    # Ransack requires lower case sort direction.
    sort_name = RANSACK_ORDER.fetch(params[:sortName], "datetime")
    sort_order = params.fetch(:sortOrder, "asc")
    search.sorts = "#{sort_name} #{sort_order.downcase}"
    # Extract HTDownload::ActiveRecord_Relation
    result = search.result
    # total is the number of results after user-selected filters e.g. {"rights_code":"pdus"}
    # totalNotFiltered (see a few lines below) is the SELECT * for the whole shebang
    total = result.count
    # Paginate using Kaminari. index UI is always paginated.
    # When exporting to Excel and the like, there is no pagination
    # (hence performance issues on large data sets).
    if params[:pageNumber] && params[:pageSize]
      result = result.page(params[:pageNumber]).per(params[:pageSize])
    end
    # Translate each row of the result into JSON and stick it into struct with totals.
    {
      total: total,
      totalNotFiltered: HTDownload.count,
      rows: result.map { |line| line_to_json line }
    }
  end

  # Use presenter to translate HTDownload into JSON hash.
  # This is called for each object in the result.
  def line_to_json(report)
    report = presenter report
    HTDownloadPresenter::ALL_FIELDS.to_h do |field|
      [field, report.field_value(field)]
    end
  end

  def presenter(report)
    HTDownloadPresenter.new(report, controller: self, action: params[:action].to_sym)
  end

  # Filter param (if any) sent by Bootstrap Table translated into Hash.
  # This will be subsequently be translated into a form Ransack can understand.
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
    if params[:dateStart]
      @matchers[:datetime_gteq] = params[:dateStart]
    end
    if params[:dateEnd]
      @matchers[:datetime_lteq] = params[:dateEnd]
    end
    @matchers
  end
end
