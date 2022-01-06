require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Otis
  class << self
    def config
      @config ||= Ettin.for(Ettin.settings_files("config", Rails.env))
    end
  end

  # eager load
  config

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.relative_url_root = Otis.config.relative_url_root

    config.action_mailer.smtp_settings = {address: Otis.config.smtp_host}

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.time_zone = "America/Detroit"
  end
end
