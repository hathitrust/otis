# frozen_string_literal: true

class ContactTypePresenter < SimpleDelegator
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def init(contact_type, _controller)
    @contact_type = contact_type
  end

  def show_link
    link_to name, contact_type_path(id)
  end

  def cancel_button
    button "Cancel", persisted? ? contact_type_path(id) : contact_types_path
  end

  private

  def controller
    # required for url helpers to work
  end

  def button(title, url)
    link_to title, url, class: "btn btn-default"
  end
end
