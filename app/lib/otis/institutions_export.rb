# frozen_string_literal: true

# Used by DailyDigestMailer to report on action items requiring attention from
# administrator.
module Otis
  class InstitutionsExport
    attr_reader :institutions
    def initialize
      @institutions = HTInstitution.all.order(:inst_id)
    end

    # Returns a String with each line being "inst_id <TAB> name"
    def instid_data
      @instid_data ||= institutions.map { |i| "#{i.inst_id}\t#{i.name}" }.join("\n")
    end

    # Returns a String with each line being "entity_id <TAB> name"
    def entityid_data
      @entityid_data ||= institutions.map { |i| "#{i.entityID}\t#{i.name}" }.join("\n")
    end
  end
end
