# frozen_string_literal: true

class OtisLogPresenter < SimpleDelegator
  def data_display
    "<code> #{data} </code>".html_safe
  end
end
