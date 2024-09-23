# frozen_string_literal: true

class HTSSDProxyReportPresenter < ApplicationPresenter
  ALL_FIELDS = %i[
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
  ].freeze

  DATA_FILTER_CONTROLS = {
    datetime: :datepicker,
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
    rights_date_used: :select
  }.freeze

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
    define_method("show_#{field}") do
      return "" if hf.nil?

      hf.send field
    end
  end

  private

  def show_datetime
    datetime.to_formatted_s(:db)
  end

  def show_email
    link_to email, ht_user_path(email)
  end

  def show_institution_name
    return "" if institution_name.nil?

    link_to institution_name, ht_institution_path(inst_code)
  end
end
