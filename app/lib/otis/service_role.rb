# frozen_string_literal: true

module Otis
  class UnknownRoleError < StandardError
    # Raised when trying to create a `ServiceRole` from a legacy `ht_users.role`
    # that does not have a modern equivalent, e.g. `staffsysadmin`
  end

  # An Object that encapsulates business logic around ht_registration.role amd ht_user.role values.
  # ht_registration uses SERVICE_ROLES.keys and maps them to slightly modified legacy values
  # when a user is created.
  # Maybe we can just go with the new SERVICE_ROLES.keys values in ht_users.role sooner or later
  # but care must be taken since the babel Perl code relies on certain legacy values.
  class ServiceRole
    SERVICE_ROLES = {
      atrs: {
        access: :normal,
        description: "Retrieve HathiTrust texts to fulfill accomodations requests from eligible users with print disabilities",
        full_name: "Accessible Text Request Service",
        name: "ATRS",
        role: :ssdproxy,
        user_type: :external
      },
      caa: {
        access: :total,
        description: "Support corrections or updates to HathiTrust volumes",
        full_name: "Collection Admin Access",
        name: "CAA",
        role: :quality,
        user_type: :external
      },
      crms: {
        access: :total,
        description: "Perform copyright review on HathiTrust volumes",
        full_name: "Copyright Review",
        name: "CRMS",
        role: :crms,
        user_type: :external
      },
      ht_staff: {
        access: :total,
        description: "Full access to all materials for HathiTrust staff members",
        full_name: "HathiTrust Staff",
        name: "HathiTrust Staff",
        role: :ht_staff,
        user_type: :staff
      },
      htus: {
        access: :total,
        description: "Respond to user inquiries received through the HathiTrust website and support email",
        full_name: "HathiTrust User Support",
        name: "HTUS",
        role: :htus,
        user_type: :external
      },
      mqip: {
        access: :total,
        description: "Perform metadata improvement, correction, and enhancement",
        full_name: "Metadata Quality Improvement Program",
        name: "MQIP",
        role: :mqip,
        user_type: :external
      },
      resource_sharing: {
        access: :normal,
        description: "Use HathiTrust texts to fulfill ILL and document delivery requests",
        full_name: "Resource Sharing",
        name: "RS",
        role: :resource_sharing,
        user_type: :external
      },
      ssd: {
        access: :normal,
        description: "Users who have print disabilities",
        full_name: "SSD User",
        name: "SSD",
        role: :ssd,
        user_type: :student
      }
    }.freeze
    private_constant :SERVICE_ROLES

    # The structure used by user and registration presenters when editing roles:
    # an Array of name-values e.g., `["Accessible Text Request Service", "ssdproxy"]`
    ROLE_OPTIONS = SERVICE_ROLES.map do |_k, v|
      [v[:full_name], v[:role]]
    end.sort_by do |option|
      option[0]
    end.freeze

    # The USER_X constants are reference lists used for DB seeding and tests.
    # There should be no reason to use these in the production code.
    #
    # All possible string values for `otis_registrations.role` and `ht_user.role`.
    USER_ROLES = SERVICE_ROLES.map { |_k, v| v[:role].to_s }.uniq.freeze
    # Ditto for `access` and `user_type`, except these are only relevant to `ht_user`
    USER_ACCESSES = SERVICE_ROLES.map { |_k, v| v[:access].to_s }.uniq.freeze
    USER_USERTYPES = SERVICE_ROLES.map { |_k, v| v[:user_type].to_s }.uniq.freeze

    # Reverse lookup for HTUser class to create ServiceRole from its
    # old fashioned role values.
    USER_ROLE_TO_SERVICE_ROLE = SERVICE_ROLES.map { |k, v| [v[:role], k] }.to_h.freeze
    private_constant :USER_ROLE_TO_SERVICE_ROLE

    attr_reader :access, :description, :full_name, :name, :role, :service_role, :user_type

    def self.keys
      SERVICE_ROLES.keys
    end

    def self.key?(...)
      SERVICE_ROLES.key?(...)
    end

    # Create a service role using the DB ht_user.role value
    def self.for_user_role(user_role)
      service_role = USER_ROLE_TO_SERVICE_ROLE[user_role.to_sym]
      if service_role.nil?
        raise UnknownRoleError, "unable to create ServiceRole for unknown user role #{user_role}"
      end

      new(service_role)
    end

    def initialize(role_key)
      @service_role = role_key.to_sym
      if !SERVICE_ROLES.key?(@service_role)
        raise UnknownRoleError, "unable to create ServiceRole for unknown role #{role_key}"
      end

      @access = SERVICE_ROLES[@service_role][:access]
      @description = SERVICE_ROLES[@service_role][:description]
      @full_name = SERVICE_ROLES[@service_role][:full_name]
      @name = SERVICE_ROLES[@service_role][:name]
      @role = SERVICE_ROLES[@service_role][:role]
      @user_type = SERVICE_ROLES[@service_role][:user_type]
    end
  end
end
