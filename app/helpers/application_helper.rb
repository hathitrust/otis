# frozen_string_literal: true

module ApplicationHelper
  def nav_menu
    %w[ht_users approval_requests ht_institutions contacts contact_types otis_logs registrations]
      .select { |item| can?(:index, item) }
      .map { |item| [item.titleize, send("#{item}_path")] }
  end
end
