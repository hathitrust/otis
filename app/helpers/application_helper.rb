# frozen_string_literal: true

module ApplicationHelper
  def nav_menu
    %w[users approval_requests institutions contacts contact_types logs registrations]
      .select { |item| can?(:index, "ht_#{item}") }
      .map { |item| {item: item, path: send(:"ht_#{item}_path")} }
      .concat(download_nav_items)
  end

  def download_nav_items
    return [] unless can?(:index, :ht_downloads)

    %w[ssdproxy resource_sharing]
      .map { |role| {item: "#{role}_downloads", path: ht_downloads_path(role)} }
  end

  # Are we on a page that requires the CKEditor 5 JS and CSS?
  # This is used in the application layout to only load those
  # heavyweight assets when needed.
  # @return [Boolean] ckeditor assets should be included
  def ckeditor?
    params[:controller] == "ht_approval_requests" && params[:action] == "edit"
  end

  # Translate "language" locale (e.g., "en" from `I18n.locale`)
  # to language-REGION locale (e.g., "en-US")
  # used by bootstrap-table.
  # This is obviously just for our available locales.
  # Defaults to US English if something goes awry.
  def language_region_locale(locale = I18n.locale)
    {en: "en-US", ja: "ja-JP"}.fetch(locale.to_sym, "en-US")
  end
end
