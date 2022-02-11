# frozen_string_literal: true

class HTContactTypePresenter < ApplicationPresenter
  ALL_FIELDS = %i[id name description].freeze
  READ_ONLY_FIELDS = %i[id].freeze
  FIELD_SIZE = 20

  private

  def show_name
    action == :index ? link_to(name, ht_contact_type_path(self)) : name
  end

  def edit_description(form:)
    form.text_area :description, size: "80x4"
  end
end
