# frozen_string_literal: true

class HTInstitutionBadge

  def initialize(tag, css_class)
    @css_class= css_class
    @tag = tag
  end

  def label_text
    I18n.t("ht_institution.badges.#{tag}")
  end

  def label_span
    "<span class='label #{css_class}'>#{label_text}</span>".html_safe
  end

  private

  attr_reader :css_class, :tag

end

class HTInstitutionPresenter < SimpleDelegator

  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  BADGES = {
    0 => HTInstitutionBadge.new('disabled','label-danger'),
    1 => HTInstitutionBadge.new('enabled','label-success'),
    2 => HTInstitutionBadge.new('private','label-warning'),
    3 => HTInstitutionBadge.new('social','label-primary')
  }

  def init(institution,controller)
    @institution = institution
  end

  def badge
    BADGES[enabled]&.label_span
  end

  def badge_options
    BADGES.map { |k,v| [v.label_text,k] }
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

  def cancel_button
    button 'Cancel', inst_id ? ht_institution_path(inst_id) : ht_institutions_path
  end

  def form_inst_id(form)
    if persisted?
      inst_id
    else
      form.text_field :inst_id
    end
  end

  def form_us(form)
    if(us)
      us_icon
    else
      form.check_box :us
    end
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
