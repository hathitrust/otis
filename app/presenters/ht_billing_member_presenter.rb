# frozen_string_literal: true

class HTBillingMemberPresenter < ApplicationPresenter
  ALL_FIELDS = %i[weight oclc_sym marc21_sym country_code status].freeze
  FIELD_SIZE = 10

  private

  def show_status
    if status
      Otis::Badge.new(self.class.value_scope + ".status.enabled", "bg-success")
    else
      Otis::Badge.new(self.class.value_scope + ".status.disabled", "bg-danger")
    end.to_html
  end

  def edit_status(form:)
    form.check_box(:status)
  end
end
