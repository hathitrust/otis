# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Otis.config.manager_email
  default bcc: Otis.config.manager_email
  default reply_to: Otis.config.reply_to_email
  layout 'mailer'
end
