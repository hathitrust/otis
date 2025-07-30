# frozen_string_literal: true

require "test_helper"

# Using recommendations at https://nicolasiensen.github.io/2022-03-11-running-rails-system-tests-with-docker/
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400],
    options: {browser: :remote, url: "http://chrome-server:4444"} do |driver_option|
    driver_option.add_argument "disable-dev-shm-usage"
  end

  setup do
    # Prevent idiotic "You are trying to work with something that isn't a file." errors
    # from Selenium when entering e-mail addresses.
    Capybara.current_session.driver.browser.file_detector = nil
  end

  def visit_with_login(url)
    visit url
    # Look for "not logged in" <p> in header and log in if necessary.
    begin
      page.find("#nav-not-logged-in")
    rescue Capybara::ElementNotFound
    else
      fill_in "username", with: "admin@default.invalid"
      click_on "Log In"
    end
  end
end
