# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Otis.config.manager_email
  default bcc: Otis.config.manager_email
  layout 'mailer'
end
