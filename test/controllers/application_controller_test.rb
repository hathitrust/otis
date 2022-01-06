# frozen_string_literal: true

require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "sets locale based on request headers" do
    save_locales = I18n.available_locales.clone
    I18n.available_locales = I18n.available_locales + [:es]
    # I18n.available_locales << :es will produce I18n::InvalidLocale for some reason
    get login_url, headers: {"Accept-Language": "es"}
    # Because locale is set in an around_action, it's reset to default
    # by the time we get here. That's why we are recording it
    # in the controller for posterity.
    assert_equal :es, controller.chosen_locale
    I18n.available_locales = save_locales
    refute_includes I18n.available_locales, :es
  end

  test "ignores bogus Accept-Language request header" do
    # I18n.available_locales << :es will produce I18n::InvalidLocale for some reason
    get login_url, headers: {"Accept-Language": "XX"}
    assert_equal :en, controller.chosen_locale
  end
end
