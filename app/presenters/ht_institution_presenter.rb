# frozen_string_literal: true

class HTInstitutionPresenter
  def self.badge_for(obj)
    @badges ||= {
      0 => "<span class='label label-danger'>#{I18n.t('ht_institution.badges.disabled')}</span>",
      1 => "<span class='label label-success'>#{I18n.t('ht_institution.badges.enabled')}</span>",
      2 => "<span class='label label-warning'>#{I18n.t('ht_institution.badges.private')}</span>",
      3 => "<span class='label label-primary'>#{I18n.t('ht_institution.badges.social')}</span>"
    }
    return '' if obj.nil?

    @badges&.[](obj.enabled)&.html_safe
  end
end
