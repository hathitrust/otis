# frozen_string_literal: true

module Otis
  # These are used in Jira EA tickets and in the landing/confirmation pages for registrants.
  # Maps between the legacy database `role` fields and the more modern way we expose
  # them to the public.
  class ServiceRole
    # This is re-used so let's just have one instance
    CAA_NAMES = {
      name: "CAA",
      full_name: "CAA"
    }.freeze

    ROLE_TO_SERVICE_NAME = {
      crms: CAA_NAMES,
      quality: CAA_NAMES,
      resource_sharing: {
        name: "RS",
        full_name: "Resource Sharing"
      },
      # We don't have any batch registration or Jira automation support for the SSD role,
      # so for now this is only included for completeness.
      ssd: {
        name: "SSD",
        full_name: "SSD"
      },
      ssdproxy: {
        name: "ATRS",
        full_name: "ATRS"
      },
      # Just using CAA as the default
      staffdeveloper: CAA_NAMES
    }.freeze

    attr_reader :role

    def initialize(role)
      @role = role.to_sym
    end

    # For creating EA tickets and to a lesser extent the landing page for registrants.
    # This sidesteps localization or coexists with it in uncomfortable ways.
    # @return String
    def name
      @name ||= ROLE_TO_SERVICE_NAME[role][:name]
    end

    # Like `#name`, but expands "RS" into "Resource Sharing" for ticket summary and description.
    # Leaves "ATRS" and "CAA" alone.
    # For now this is the only acronym that gets expanded but we may want to do the others.
    # @return String
    def full_name
      @full_name ||= ROLE_TO_SERVICE_NAME[role][:full_name]
    end
  end
end
