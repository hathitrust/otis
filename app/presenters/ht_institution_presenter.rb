# frozen_string_literal: true

class HTInstitutionPresenter < SimpleDelegator

  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def init(institution,controller)
    @institution = institution
  end

  def badge
    @badges ||= {
      0 => "<span class='label label-danger'>#{I18n.t('ht_institution.badges.disabled')}</span>",
      1 => "<span class='label label-success'>#{I18n.t('ht_institution.badges.enabled')}</span>",
      2 => "<span class='label label-warning'>#{I18n.t('ht_institution.badges.private')}</span>",
      3 => "<span class='label label-primary'>#{I18n.t('ht_institution.badges.social')}</span>"
    }

    @badges[enabled]&.html_safe
  end

  def us_icon
    raw us ? '<i class="glyphicon glyphicon-ok"></i>' : ''
  end

  def etas_active_icon
    raw emergency_status ? '<i class="glyphicon glyphicon-ok"></i>' : ''
  end

  def formatted_mapto_name
    mapto_name || "(None)"
  end

  def emergency_contact_link
    (link_to emergency_contact, "mailto:#{emergency_contact}" if emergency_contact) || "(None)"
  end

  def etas_affiliations
    emergency_status || "(ETAS not enabled)"
  end

  def login_test_link
    button 'Test Login', login_test_url
  end

  def mapped_inst_link
    (link_to mapto_inst_id, ht_institution_path(mapto_inst_id) if mapto_inst_id) || "(None)"
  end

  def metadata_link
    link_to entityID, metadata_url(entityID) if entityID
  end

  def mfa_test_link
    button 'Test Login with MFA', mfa_test_url if entityID && shib_authncontext_class
  end

  def grin_link
    link_to grin_instance, "#{google_books_base}/libraries/#{grin_instance}" if grin_instance
  end

  private


  def controller
    # required for url helpers to work
  end

  def button(title, url)
    link_to title, url, class: 'btn btn-default'
  end

  # TODO get from config

  def met_base
    "https://met.refeds.org"
  end

  def ht_base
    "https://babel.hathitrust.org"
  end

  def google_books_base
    "https://books.google.com"
  end

  def login_test_url(eid=entityID)
    "#{ht_base}/Shibboleth.sso/Login?entityID=#{eid}&target=#{ht_base}/cgi/whoami"
  end

  def mfa_test_url(eid=entityID)
    "#{ht_base}/Shibboleth.sso/Login?entityID=#{eid}&authnContextClassRef=#{shib_authncontext_class}&target=#{ht_base}/cgi/whoami"
  end

  def metadata_url(eid=entityID)
    "#{met_base}/met/entity/#{eid}"
  end
end
