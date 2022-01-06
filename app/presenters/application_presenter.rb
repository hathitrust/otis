# frozen_string_literal: true

class ApplicationPresenter < SimpleDelegator
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  attr_reader :action, :controller

  # Master list of fields that could be displayed on any page.
  ALL_FIELDS = %i[].freeze

  # Not displayed on the show page
  HIDDEN_FIELDS = %i[].freeze

  # Displayed on the edit page but not editable
  READ_ONLY_FIELDS = %i[].freeze

  # Only editable when creating a new object
  READ_ONLY_AFTER_PERSISTED_FIELDS = %i[].freeze

  # Default character size of editable fields
  FIELD_SIZE = 60

  def self.attribute_scope
    @attribute_scope ||= "activerecord.attributes." + name.sub(%r{Presenter$}, "").underscore
  end

  def self.value_scope
    @value_scope ||= name.sub(%r{Presenter$}, "").underscore + ".values"
  end

  def self.field_label(field)
    I18n.t(field, scope: attribute_scope)
  end

  def initialize(obj, controller: nil, action: :show)
    super obj
    @controller = controller
    @action = action
  end

  # By default form cancel button goes to show page if persisted,
  # index page otherwise.
  def cancel_path
    if persisted?
      method = (self.class.name.sub(%r{Presenter$}, "").underscore + "_path").to_sym
      send method, self
    else
      method = (self.class.name.sub(%r{Presenter$}, "").pluralize.underscore + "_path").to_sym
      send method
    end
  end

  def editable?(field, form: nil)
    return false if form.nil?
    return false if self.class::READ_ONLY_FIELDS.include?(field)
    return false if persisted? && self.class::READ_ONLY_AFTER_PERSISTED_FIELDS.include?(field)

    true
  end

  def field_label(field, form: nil)
    return "" if self.class::HIDDEN_FIELDS.include?(field) && action == :show

    if editable?(field, form: form)
      form.label field
    else
      self.class.field_label(field)
    end.to_s.html_safe
  end

  def field_value(field, form: nil)
    return "" if self.class::HIDDEN_FIELDS.include?(field) && action == :show

    if editable?(field, form: form)
      edit_field_value(field, form: form)
    else
      show_field_value field
    end.to_s.html_safe
  end

  private

  def show_field_value(field)
    method = ("show_" + field.to_s).to_sym
    if respond_to?(method, true)
      send(method) || ""
    else
      localize_value field
    end
  end

  def localize_value(field)
    value = try(field) || return

    begin
      I18n.t(self.class.value_scope + ".#{field}.#{value}", raise: true)
    rescue I18n::ArgumentError
      ERB::Util.html_escape value
    end
  end

  def edit_field_value(field, form:)
    if respond_to?(("edit_" + field.to_s).to_sym, true)
      send ("edit_" + field.to_s).to_sym, form: form
    else
      edit_field_value_default field, form: form
    end
  end

  def edit_field_value_default(field, form:)
    form.text_field field, size: self.class::FIELD_SIZE
  end
end
