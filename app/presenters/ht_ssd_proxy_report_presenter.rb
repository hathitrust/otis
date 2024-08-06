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

  def self.data_filter_control(field)
    DATA_FILTER_CONTROLS[field].to_s
  end

  private

  def show_author
    hf.author
  end

  def show_datetime
    datetime.to_formatted_s(:db)
  end

  def show_email
    link_to email, ht_user_path(email)
  end

  def show_bib_num
    hf.bib_num
  end

  def show_content_provider_code
    hf.content_provider_code
  end

  def show_digitization_agent_code
    hf.digitization_agent_code
  end

  def show_imprint
    hf.imprint
  end

  def show_institution_name
    return "" if institution_name.nil?

    link_to institution_name, ht_institution_path(inst_code)
  end

  def show_rights_code
    hf.rights_code
  end

  def show_rights_date_used
    hf.rights_date_used
  end

  def show_title
    hf.title
  end
end
