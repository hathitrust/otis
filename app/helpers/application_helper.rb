# frozen_string_literal: true

module ApplicationHelper
  def nav_menu
    %w[users approval_requests institutions contacts contact_types logs]
      .select { |item| can?(:index, "ht_#{item}") }
      .map { |item| [item.titleize, send("ht_#{item}_path")] }
  end
end
