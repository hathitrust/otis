# frozen_string_literal: true

class HTLogPresenter < SimpleDelegator
  def data_display
    "<code> #{data} </code>".html_safe
  end
end
