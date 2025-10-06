# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::AssetTagHelper

  default from: Otis.config.manager_email
  default bcc: Otis.config.manager_email
  default reply_to: Otis.config.reply_to_email
  layout "mailer"

  def default_url_options(options = {})
    ActionMailer::Base.default_url_options
      .merge(locale: I18n.locale)
      .merge(options)
  end

  # Add the image file as an attachment
  # Typically called by a mailer subclass directly
  def add_email_signature_logo
    signature_file = File.read("#{Rails.root}/public/images/#{Otis.config.image.hathitrust.email_signature_logo.name}")
    attachments.inline[Otis.config.image.hathitrust.email_signature_logo.name] = signature_file
  end

  # Display the attached image file in the email body
  # Typically called from a view template
  def show_email_signature_logo
    image_tag(attachments[Otis.config.image.hathitrust.email_signature_logo.name].url,
      size: Otis.config.image.hathitrust.email_signature_logo.size,
      alt: "HathiTrust logo")
  end
end
