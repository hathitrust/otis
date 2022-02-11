# frozen_string_literal: true

class HTLogPresenter < ApplicationPresenter
  ALL_FIELDS = %i[model objid time data].freeze

  private

  def show_data
    "<code>#{data}</code>"
  end

  def show_time
    I18n.l(time, format: :long)
  end
end
