# frozen_string_literal: true

class HTDownloadPresenter < ApplicationPresenter
  # All the columns in the index page.
  ALL_FIELDS = %i[
    role
    datetime
    htid
    bib_num
    rights_code
    email
    inst_code
    institution_name
    content_provider_code
    digitization_agent_code
    title
    imprint
    author
    rights_date_used
    full_download
    pages
    seq
  ].freeze

  # Type of filter control to specify for a given column.
  DATA_FILTER_CONTROLS = {
    role: :select,
    datetime: :input,
    htid: :input,
    bib_num: :input,
    rights_code: :select,
    email: :input,
    inst_code: :select,
    institution_name: :select,
    content_provider_code: :select,
    digitization_agent_code: :select,
    title: :input,
    imprint: :input,
    author: :input,
    rights_date_used: :input,
    full_download: :select,
    pages: :input
  }.freeze

  # Used below to create accessor methods for the relevant hathifiles.hf fields.
  HF_FIELDS = %i[
    author
    bib_num
    content_provider_code
    digitization_agent_code
    imprint
    rights_code
    rights_date_used
    title
  ].freeze

  def self.data_filter_control(field)
    DATA_FILTER_CONTROLS[field].to_s
  end

  # Display all possible values for a given column that has a popup menu
  # Maps display value and query values (which are the same except for role).
  # Should not be memoized, locale is variable.
  # Returns a hash of { "search_value" => "Display Value", ... }
  def self.data_filter_data(field)
    return if DATA_FILTER_CONTROLS[field] != :select

    all_values = HTDownload.all_values(field)
    all_values_map = all_values.to_h { |x| [x, x] }
    # Postprocess role because displayed values are localized and anyway
    # differ from the stored values.
    if field == :role
      all_values_map.each_key do |value|
        all_values_map[value] = I18n.t(value_scope + ".#{field}.#{value}", raise: false)
      end
    end
    if field == :full_download
      # TODO: duplication with `show_full_download`, sidesteps localization.
      # We have some overly complex ransacker plumbing in here just to support "yes" and "no"
      # ETT-745 may give us the opportunity to return {0 => "no", 1 => "yes"} or {false => "no", true => "yes"}
      # and get rid of the ransacker and some other goop.
      all_values_map = all_values.to_h { |x| x ? ["yes", "yes"] : ["no", "no"] }
    end
    ("json:" + all_values_map.to_json).html_safe
  end

  def self.data_visible(field)
    field != :seq
  end

  # Some CSS in index.html.erb allows the title, imprint, and author fields to be a bit wider
  # than the default.
  def self.header_class(field)
    case field
    when :title, :imprint
      "min--250"
    when :author
      "min--150"
    else
      ""
    end
  end

  # Dynamically create simple #show_X methods for each hf column we display in the index.
  # Could also define these on the model.
  HF_FIELDS.each do |field|
    define_method(:"show_#{field}") do
      return "" if hf.nil?

      hf.send field
    end
  end

  private

  # More or less standard `show_X` methods when we want to customize the display.
  # We could check the `link_to` targets to make sure they actually exist, but it's unlikely
  # we would ever get a 404 since we don't typically jettison users or institutions.

  def show_datetime
    "<span class=\"text-nowrap\">#{datetime.to_formatted_s(:db)}</span>"
  end

  def show_role
    "<span class=\"text-nowrap\">#{localize_value(:role)}</span>"
  end

  def show_email
    link_to email, ht_user_path(email)
  end

  def show_institution_name
    return "" if institution_name.nil?

    link_to institution_name, ht_institution_path(inst_code)
  end

  def show_full_download
    full_download ? "yes" : "no"
  end
end
