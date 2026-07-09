# frozen_string_literal: true

module Otis
  # An Object that encapsulates business logic around ht_registration.role amd ht_user.role values.
  # ht_registration uses SERVICE_ROLES.keys and maps them to slightly modified legacy values
  # when a user is created.
  # Maybe we can just go with the new SERVICE_ROLES.keys values in ht_users.role sooner or later
  # but care must be taken since the babel Perl code relies on certain legacy values.
  # TODO: consider moving this data to YML?

  class ServiceRole
    SERVICE_ROLES = {
      atrs: {
        access: :normal,
        description: "Correct or add to the bibliographic records of HathiTrust volumes",
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
        name: "Staff",
        role: :ht_staff,
        user_type: :staff
      },
      resource_sharing: {
        access: :normal,
        description: "Use full-view texts to fulfill ILL and document delivery requests",
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

    # Reverse lookup for HTUser class to create ServiceRole from its
    # old fashioned role values.
    USER_ROLE_TO_SERVICE_ROLE = SERVICE_ROLES.map { |k, v| [v[:role], k] }.to_h

    attr_reader :access, :description, :full_name, :name, :role, :service_role, :user_type

    def self.keys
      SERVICE_ROLES.keys
    end

    def self.key?(...)
      SERVICE_ROLES.key?(...)
    end

    # Create a service role using the legacy ht_user.role value
    def self.for_user_role(user_role)
      service_role = USER_ROLE_TO_SERVICE_ROLE[user_role.to_sym]
      new(service_role)
    end

    def initialize(role_key)
      @service_role = role_key.to_sym
      unless SERVICE_ROLES.key?(@service_role)
        raise "unable to create ServiceRole for unknown role #{@service_role}"
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
