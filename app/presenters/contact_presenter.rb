# frozen_string_literal: true

class ContactPresenter < SimpleDelegator
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def init(contact, _controller)
    @contact = contact
  end

  def inst_link
    link_to institution_display, contact_path(id)
  end

  def institution_display
    ht_institution&.name
  end

  def contact_type_display
    contact_type&.name
  end

  def email_display
    mailto_link email
  end

  def cancel_button
    button "Cancel", persisted? ? contact_path(id) : contacts_path
  end

  private

  def controller
    # required for url helpers to work
  end

  def button(title, url)
    link_to title, url, class: "btn btn-default"
  end

  def mailto_link(value)
    (link_to value, "mailto:#{value}" if value) || "(None)"
  end
end
