# frozen_string_literal: true

JIRA_BASE_URL = "https://tools.lib.umich.edu/jira/browse"

class HTRegistrationPresenter < SimpleDelegator
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def init(registration, _controller)
    @registration = registration
  end

  def controller
    # loadbearing noop
  end

  def jira_link
    link_to jira_ticket, "#{JIRA_BASE_URL}/#{jira_ticket}"
  end

  def edit_link
    link_to name, ht_registration_path(id)
  end

  def inst_link
    link_to inst_id, ht_institution_path(inst_id)
  end

  def contact(name, email, date)
    [name, link_to(email, "mailto:#{email}"), date].join("<br>")
  end
  
  def auth_contact
    contact(auth_rep_name, auth_rep_email, auth_rep_date)
  end

  def dsp_contact
    contact(dsp_name, dsp_email, dsp_date)
  end
end
