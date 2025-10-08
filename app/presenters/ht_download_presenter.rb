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
    pages
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
    rights_date_used: :select,
    pages: :select
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

  def show_pages
    if pages
      pages
    elsif !partial?
      "all"
    else
      # partial download but no page count recorded
      "unknown"
    end
  end
end
