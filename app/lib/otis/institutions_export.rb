# frozen_string_literal: true

# Used by DailyDigestMailer to report on action items requiring attention from
# administrator.
module Otis
  class InstitutionsExport
    attr_reader :enabled_institutions, :enabled_for_login_institutions
    def initialize
      @enabled_institutions = HTInstitution.where.not(enabled: 0).order(:inst_id)
      @enabled_for_login_institutions = HTInstitution.enabled.order(:inst_id)
    end

    # Returns a String with each line being "inst_id <TAB> name"
    # Includes all institutions but those with enabled=0
    def instid_data
      @instid_data ||= enabled_institutions.map { |i| "#{i.inst_id}\t#{i.name}" }.join("\n")
    end

    # Returns a String with each line being "entity_id <TAB> name"
    # Only includes institutions with enabled=1 (excludes social login and private)
    def entityid_data
      @entityid_data ||= enabled_for_login_institutions.map { |i| "#{i.entityID}\t#{i.name}" }.join("\n")
    end
  end
end
