# frozen_string_literal: true

module Otis
  # An Object that encapsulates business logic around ht_user.role values.
  # TODO: consider moving this data to YML?

  class ServiceRole
    SERVICE_ROLES = {
      cataloging: {
        access: :total,
        description: "Correct or add to the bibliographic records of HathiTrust volumes",
        full_name: "Cataloging",
        name: "Cataloging",
        service: :caa,
        usertype: [:staff] # No attested external members with this role currently
      },
      corrections: {
        access: :total,
        description: "Support corrections or updates to HathiTrust volumes",
        full_name: "Corrections",
        name: "Corrections",
        service: :caa,
        usertype: [:external, :staff]
      },
      crms: {
        access: :total,
        description: "Perform copyright review on HathiTrust volumes",
        full_name: "Copyright Review",
        name: "CRMS",
        service: :caa,
        usertype: [:external, :staff]
      },
      quality: {
        access: :total,
        description: "Evaluate the quality of digital volumes in HathiTrust",
        full_name: "Quality",
        name: "Quality",
        service: :caa,
        usertype: [:external] # No attested staff members with this role
      },
      replacement: {
        access: :total,
        description: "Create replacement copies of individual pages of volumes in HathiTrust",
        full_name: "Replacement",
        name: "Replacement",
        service: :caa,
        usertype: [:external, :staff]
      },
      resource_sharing: {
        access: :normal,
        description: "Use full-view texts to fulfill ILL and document delivery requests",
        full_name: "Resource Sharing",
        name: "Resource Sharing",
        service: :rs,
        usertype: [:external, :staff] # The fact that we have staff with RS is probably a temporary anomaly
      },
      ssd: {
        access: :normal,
        description: "Users who have print disabilities",
        full_name: "Accessible Text Request Service Patron",
        name: "ATRS Patron",
        service: :ssd,
        usertype: [:student]
      },
      ssdproxy: {
        access: :normal,
        description: "Act as a proxy for users who have print disabilities",
        full_name: "Accessible Text Request Service Provider",
        name: "ATRS Provider",
        service: :atrs,
        usertype: [:external]
      },
      staffdeveloper: {
        access: :total,
        description: "Develop software for HathiTrust services or operations",
        full_name: "Staff Developer",
        name: "Staff Developer",
        service: :caa,
        usertype: [:staff] # Two in staffdeveloper currently are marked external but DB should be corrected
      },
      staffsysadmin: {
        access: :total,
        deprecated: true,
        description: "Operate or maintain HathiTrust repository infrastructure",
        full_name: "Staff Sysadmin",
        name: "Staff Sysadmin",
        service: :caa,
        usertype: [:staff]
      },
      # FIXME: get rid of this if possible (is it attested in inactive users?)
      superuser: {
        access: :total,
        deprecated: true,
        description: "UM staff developer – includes roles staffdeveloper and staffsysadmin",
        full_name: "Superuser",
        name: "Superuser",
        service: :caa,
        usertype: [:staff]
      }
    }.freeze

    attr_reader :access, :description, :full_name, :name, :role, :service

    # Returns the currently-used roles found in ht_users and otis_registrations
    def self.role_keys
      SERVICE_ROLES.keys
    end

    def initialize(role)
      @role = role.to_sym
      unless SERVICE_ROLES.key?(@role)
        raise "unable to create ServiceRole for unknown role #{@role}"
      end
      @access = SERVICE_ROLES[@role][:access]
      @description = SERVICE_ROLES[@role][:description]
      @deprecated = SERVICE_ROLES[@role].fetch(:deprecated, false)
      @full_name = SERVICE_ROLES[@role][:full_name]
      @name = SERVICE_ROLES[@role][:name]
      @service = Service.new(@role)
    end
  end
end
