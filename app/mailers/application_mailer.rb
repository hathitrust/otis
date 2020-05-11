# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'hathitrust-system@umich.edu'
  layout 'mailer'
end
