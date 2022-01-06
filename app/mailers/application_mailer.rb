# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Otis.config.manager_email
  default bcc: Otis.config.manager_email
  default reply_to: Otis.config.reply_to_email
  layout "mailer"

  def default_url_options(options = {})
    ActionMailer::Base.default_url_options
      .merge(locale: I18n.locale)
      .merge(options)
  end
end
