I18n.default_locale = :en
# Experimental/bogus Japanese locale only in dev/test
I18n.available_locales = Rails.env.production? ? [:en] : [:en, :ja]
