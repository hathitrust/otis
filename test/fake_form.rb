# frozen_string_literal: true

# Fake FormBuilder for presenter tests.
# Emits just enough information to let us know it's doing something.
class FakeForm
  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    "SELECT"
  end

  # label -> LABEL
  # text_field -> TEXT FIELD
  # text_area -> TEXT AREA
  def method_missing(m, *args, &block)
    m.to_s.tr("_", " ").upcase
  end

  def respond_to_missing?(method, *args)
    true
  end
end
