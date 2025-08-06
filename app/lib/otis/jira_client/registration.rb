# frozen_string_literal: true

require "jira-ruby"

module Otis
  class JiraClient::Registration < JiraClient
    attr_reader :registration, :finalize_url

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
    # "Registration completed" value for EA_REGISTRATION_EA_WORKFLOW_FIELD
    EA_REGISTRATION_COMPLETED_WORKFLOW_ID = "10553"
    # "Registration completed" value for EA_REGISTRATION_EA_WORKFLOW_FIELD
    EA_REGISTRATION_APPROVED_WORKFLOW_ID = "10554"
    # Transition to "consulting with staff" status
    EA_REGISTRATION_ESCALATE_TRANSITION_ID = "921"
    # Transition to "closed" status
    EA_REGISTRATION_RESOLVE_TRANSITION_ID = "761"

    # Controller passes in the finalize URL, otherwise we risk getting "Missing host to link to!" exceptions.
    # This must be set when creating/updating the initial ticket, not needed if just calling
    # `finish!` or `finalize!`
    def initialize(registration, finalize_url = nil)
      raise "no registration??" unless registration.present?
      @registration = registration
      @finalize_url = finalize_url
      super()
    end

    # Returns true if a new ticket was created, false otherwise
    def update_ea_ticket!
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
    def issue
      @issue ||= if has_ea_ticket?
        @client.Issue.find(registration.jira_ticket)
      else
        @client.Issue.build
      end
    end

    # registration.role translated into ATRS/CAA/RS
    # @return String
    def service_name
      @service_name ||= @registration.service_name
    end

    # registration.role translated into ATRS/CAA/Resource Sharing
    # @return String
    def full_service_name
      @full_service_name ||= @registration.service_name(expand: true)
    end

    def ea_fields
      {
        fields: {
          :summary => "#{full_service_name} Registration for #{registration.applicant_email}",
          :description => "#{full_service_name} Registration for #{registration.applicant_name} <#{registration.applicant_email}>",
          :project => {key: Otis.config.jira.elevated_access_project},
          :labels => [service_name],
          :issuetype => {id: EA_REGISTRATION_ISSUETYPE_ID},
          EA_REGISTRATION_LINK_FIELD => finalize_url,
          EA_REGISTRATION_EA_TYPE_FIELD => {value: service_name},
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

    # ETT-220
    # After registrant has visited verification URL (i.e., `registration.received` is filled):
    # - Set "EA workflow" (EA_REGISTRATION_EA_WORKFLOW_FIELD) to "Registration completed" (EA_REGISTRATION_COMPLETED_WORKFLOW_ID)
    # - Set ticket status to "Consulting with staff" via the "escalate" transition (EA_REGISTRATION_ESCALATE_TRANSITION_ID)
    # - Add internal comment "registration submitted by #{registration.applicant_email}"
    def finalize!
      fields = {
        fields: {
          EA_REGISTRATION_EA_WORKFLOW_FIELD => {id: EA_REGISTRATION_COMPLETED_WORKFLOW_ID}
        }
      }
      issue.save fields
      issue_transition = issue.transitions.build
      issue_transition.save!(transition: {id: EA_REGISTRATION_ESCALATE_TRANSITION_ID})
      internal_comment!(issue: issue, comment: "registration submitted by #{registration.applicant_email}")
    end

    # ETT-292
    # Called when new ht_user is created from registration.
    # - Set "EA workflow" (EA_REGISTRATION_EA_WORKFLOW_FIELD) to “Registration approved” (EA_REGISTRATION_APPROVED_WORKFLOW_ID)
    # - Add internal note to EA ticket: “registration finished for [otisRegistrantEmail]”
    # - If ETT-221 is to trigger when the issue is transitioned to Done, do it here (EA_REGISTRATION_RESOLVE_TRANSITION_ID)
    def finish!
      fields = {
        fields: {
          EA_REGISTRATION_EA_WORKFLOW_FIELD => {id: EA_REGISTRATION_APPROVED_WORKFLOW_ID}
        }
      }
      issue.save fields
      # This part (transition, next two lines) is not set in stone.
      issue_transition = issue.transitions.build
      issue_transition.save!(transition: {id: EA_REGISTRATION_RESOLVE_TRANSITION_ID})
      internal_comment!(issue: issue, comment: "registration finished for #{registration.applicant_email}")
    end
  end
end
