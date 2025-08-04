# frozen_string_literal: true

require "jira-ruby"

module Otis
  class JiraClient::Registration < JiraClient
    attr_reader :registration, :finalize_url

    # ETT-220 TODO: this may be removed
    COMMENT_TEMPLATES = {
      registration_sent: "OTIS status update: registration e-mail sent to __USER__.",
      registration_received: "OTIS status update: registration submitted by __USER__.",
      registration_finished: "OTIS status update: registration finished for __USER__."
    }.freeze

    ROLE_TO_REGISTRATION_TYPE = {
      crms: "CAA",
      quality: "CAA",
      resource_sharing: "RS",
      # We don't have any batch registration or Jira automation support for the SSD role,
      # so for now this is only included for completeness.
      ssd: "SSD",
      ssdproxy: "ATRS",
      # Just using CAA as the default
      staffdeveloper: "CAA"
    }.freeze

    # ETT-220 TODO: this may be removed
    def self.comment(template:, user:)
      COMMENT_TEMPLATES[template].gsub("__USER__", user)
    end

    # "Elevated access registration" issuetype
    EA_REGISTRATION_ISSUETYPE_ID = "10715"
    # "EA workflow" field
    # Possible values: "Registration email pending" etc.
    # Not used in ticket creation but may be used to update status to kick off subsequent workflows.
    EA_REGISTRATION_EA_WORKFLOW_FIELD = :customfield_10328
    # "EA registration link" field
    EA_REGISTRATION_LINK_FIELD = :customfield_10329
    # "EA registrant email" field
    EA_REGISTRATION_EMAIL_FIELD = :customfield_10361
    # "EA type" field
    EA_REGISTRATION_EA_TYPE_FIELD = :customfield_10362
    # "Related GS ticket number" field
    EA_REGISTRATION_GS_TICKET_FIELD = :customfield_10363
    # "EA registrant name" field
    EA_REGISTRATION_NAME_FIELD = :customfield_10427

    # Controller passes in the finalize URL, otherwise we risk getting "Missing host to link to!" exceptions.
    def initialize(registration, finalize_url)
      raise "no registration??" unless registration.present?
      @registration = registration
      @finalize_url = finalize_url
      super()
    end

    # Returns true if a new ticket was created, false otherwise
    def update_ea_ticket!
      issue = ea_issue
      issue.save ea_fields
      if has_ea_ticket?
        false
      else
        registration.jira_ticket = issue.key
        true
      end
    end

    # False if blank or GS, true if EA
    def has_ea_ticket?
      registration.jira_ticket&.start_with?(Otis.config.jira.elevated_access_project)
    end

    # If there's a GS ticket, or no ticket, in the registration, always create a new EA ticket.
    # If there's an EA ticket then we keep using that one.
    def ea_issue
      if has_ea_ticket?
        @client.Issue.find(registration.jira_ticket)
      else
        @client.Issue.build
      end
    end

    # Translate registration.role into ATRS/CAA/RS
    # @return String
    def ea_type
      @ea_type ||= ROLE_TO_REGISTRATION_TYPE[registration.role.to_sym]
    end

    # Expands "RS" into "Resource Sharing" for ticket summary and description.
    # Leaves "ATRS" and "CAA" alone.
    # For now this is the only acronym that gets expanded but we may want to do the others.
    # @return String
    def ea_type_full
      @ea_type_full ||= ((ea_type == "RS") ? "Resource Sharing" : ea_type)
    end

    def ea_fields
      {
        fields: {
          :summary => "#{ea_type_full} Registration for #{registration.applicant_email}",
          :description => "#{ea_type_full} Registration for #{registration.applicant_name} <#{registration.applicant_email}>",
          :project => {key: Otis.config.jira.elevated_access_project},
          :labels => [ea_type],
          :issuetype => {id: EA_REGISTRATION_ISSUETYPE_ID},
          EA_REGISTRATION_LINK_FIELD => finalize_url,
          EA_REGISTRATION_EA_TYPE_FIELD => {value: ea_type},
          # MS will use this to kick off the email, don't set it here unless we want to send the email automatically
          # EA_REGISTRATION_EA_WORKFLOW_FIELD => {value: "Registration email pending"},
          EA_REGISTRATION_EMAIL_FIELD => registration.applicant_email,
          EA_REGISTRATION_NAME_FIELD => registration.applicant_name
        }
      }.tap do |data|
        if !has_ea_ticket?
          data[:fields][EA_REGISTRATION_GS_TICKET_FIELD] = registration.jira_ticket
        end
      end
    end
  end
end
