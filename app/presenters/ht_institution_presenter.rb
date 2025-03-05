# frozen_string_literal: true

class HTInstitutionPresenter < ApplicationPresenter
  ENABLED_MAP = {
    0 => "disabled",
    1 => "enabled",
    2 => "private",
    3 => "social"
  }.freeze

  BADGES = {
    0 => Otis::Badge.new(value_scope + ".enabled.disabled", "bg-danger"),
    1 => Otis::Badge.new(value_scope + ".enabled.enabled", "bg-success"),
    2 => Otis::Badge.new(value_scope + ".enabled.private", "bg-warning text-dark"),
    3 => Otis::Badge.new(value_scope + ".enabled.social", "bg-primary")
  }.freeze

  ETAS_BADGES = {
    enabled: Otis::Badge.new(value_scope + ".emergency_status.etas_enabled", "bg-success"),
    disabled: Otis::Badge.new(value_scope + ".emergency_status.etas_not_enabled", "bg-danger")
  }.freeze

  ALL_FIELDS = %i[
    inst_id domain name mapto_name entityID mapto_inst_id template us
    grin_instance shib_authncontext_class allowed_affiliations emergency_status enabled
    last_update
  ].freeze

  INDEX_FIELDS = %i[inst_id name domain us entityID emergency_status].freeze
  INDEX_FIELDS_INACTIVE = %i[inst_id name domain us enabled entityID].freeze
  READ_ONLY_FIELDS = %i[last_update].freeze
  READ_ONLY_AFTER_PERSISTED_FIELDS = %i[inst_id].freeze

  def badge_options
    BADGES.map { |k, v| [v.label_text, k] }
  end

  def user_count
    HTUser.where(inst_id: inst_id).count
  end

  def active_user_count
    HTUser.active.where(inst_id: inst_id).count
  end

  def contacts
    HTContact.for_institution(id).map { |c| HTContactPresenter.new c }
  end

  def login_test_url
    "#{Otis.config.ht_login_test_endpoint}&entityID=#{entityID}"
  end

  def mfa_test_url
    "#{login_test_url}&authnContextClassRef=#{shib_authncontext_class}"
  end

  private

  def etas_badge
    ETAS_BADGES[emergency_status.present? ? :enabled : :disabled].label_span
  end

  def show_allowed_affiliations
    "<code>#{allowed_affiliations}</code>"
  end

  # Index version: ETAS badge or blank
  # Non-index version: code value or "not enabled"
  def show_emergency_status
    if action == :index
      emergency_status.present? ? etas_badge : ""
    elsif emergency_status.present?
      "<code>#{emergency_status}</code>"
    else
      etas_badge
    end
  end

  def show_enabled
    BADGES[enabled]&.label_span
  end

  def show_entityID
    link_to entityID, "#{Otis.config.met_entity_endpoint}/#{entityID}" if entityID
  end

  def show_grin_instance
    link_to grin_instance, "#{Otis.config.books_library_endpoint}/#{grin_instance}" if grin_instance
  end

  def show_inst_id
    if action == :index
      link_to(inst_id, ht_institution_path(inst_id))
    else
      inst_id
    end
  end

  def show_last_update
    last_update ? I18n.l(Time.zone.parse(last_update.to_s).to_date, format: :long) : ""
  end

  def show_mapto_inst_id
    link_to(mapto_inst_id, ht_institution_path(mapto_inst_id)) if mapto_inst_id
  end

  # should this be done in CSS?
  # This is a bit larger than the Rails 6 version which was 21.333x16
  def show_us
    us ? ActionController::Base.helpers.image_tag("us_flag.svg", size: "24x18", alt: "US Flag") : ""
  end

  def edit_enabled(form:)
    form.select :enabled, badge_options
  end

  def edit_us(form:)
    form.check_box :us
  end
end
