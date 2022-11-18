# frozen_string_literal: true

class HTContactPresenter < ApplicationPresenter
  ALL_FIELDS = %i[id inst_id contact_type email].freeze
  READ_ONLY_FIELDS = %i[id].freeze
  FIELD_SIZE = 30

  private

  def show_email
    return "" unless email.present?

    link_to(email, action == :index ? ht_contact_path(self) : "mailto:#{email}")
  end

  def show_inst_id
    return "" if ht_institution.nil?

    link_to ht_institution.name, ht_institution_path(ht_institution)
  end

  def show_contact_type
    link_to ht_contact_type.name, ht_contact_type_path(ht_contact_type)
  end

  def edit_inst_id(form:)
    form.collection_select(:inst_id, HTInstitution.enabled.all, :inst_id, :name,
      {}, {class: "select-institution"})
  end

  def edit_contact_type(form:)
    form.collection_select(:contact_type, HTContactType.all, :id, :name)
  end
end
