# frozen_string_literal: true

require "jira-ruby"

module Otis
  # Handles the three phases of the registration workflow where Otis communicates with Jira.
  # In sequential order:
  # - Registration creation (and update)
  #   - Otis creates/updates a Jira ticket in the "EA" project with:
  #     - Summary
  #     - Project ("EA")
  #     - Labels (just "EA")
  #     - Issuetype (EA_REGISTRATION_ISSUETYPE_ID)
  #     - Registration link (custom field)
  #     - EA type (custom field)
  #     - GS ticket (custom field - if supplied)
  #     - Email (custom field)
  #     - Name (custom field)
  # - Registration submission (`submit!`)
  #   - Set "EA workflow" (EA_REGISTRATION_EA_WORKFLOW_FIELD) to “Registration approved” (EA_REGISTRATION_APPROVED_WORKFLOW_ID)
  #   - Add internal comment “registration approved for #{registration.applicant_email}”
  #   - Set ticket status to "Waiting for support" (automation will close it)
  # - Registration approval (`approve!`)
  #   - Set "EA workflow" (EA_REGISTRATION_EA_WORKFLOW_FIELD) to "Registration completed" (EA_REGISTRATION_SUBMITTED_WORKFLOW_ID)
  #   - Add internal comment "registration submitted by #{registration.applicant_email}"
  #   - Set ticket status to "Consulting with staff"
  # Note no effort is made to localize the various text values we are submitting.
  #
  # There are several Jira automations which handle sending e-mail to registrant and
  # other housekeeping chores:
  # See https://hathitrust.atlassian.net/jira/servicedesk/projects/EA/settings/automate
  class JiraClient::Registration < JiraClient
    attr_reader :registration, :submit_url

    # "Elevated access registration" issuetype
    EA_REGISTRATION_ISSUETYPE_ID = "10715"
    # "EA workflow" field
    # Possible values: "Registration email pending" etc.
    # Not used in ticket creation but used to kick off subsequent sutomations.
    # Possuble values are 10551 thru 10554 (see below)
    EA_REGISTRATION_EA_WORKFLOW_FIELD = :customfield_10328
    # "EA registration link" field
    EA_REGISTRATION_LINK_FIELD = :customfield_10460
    # "EA registrant email" field
    EA_REGISTRATION_EMAIL_FIELD = :customfield_10361
    # "EA type" field
    EA_REGISTRATION_EA_TYPE_FIELD = :customfield_10362
    # "Related GS ticket number" field
    EA_REGISTRATION_GS_TICKET_FIELD = :customfield_10363
    # "EA registrant name" field
    EA_REGISTRATION_NAME_FIELD = :customfield_10427
    # "Registration completed" value for EA_REGISTRATION_EA_WORKFLOW_FIELD
    EA_REGISTRATION_SUBMITTED_WORKFLOW_ID = "10553"
    # "Registration approved" value for EA_REGISTRATION_EA_WORKFLOW_FIELD
    EA_REGISTRATION_APPROVED_WORKFLOW_ID = "10554"

    # Controller passes in the submit URL, otherwise we risk getting "Missing host to link to!" exceptions.
    # This must be set when creating/updating the initial ticket, not needed if just calling
    # `submit!` or `approve!`
    def initialize(registration, submit_url = nil)
      raise "no registration??" unless registration.present?
      @registration = registration
      @submit_url = submit_url
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

    def ea_fields
      {
        fields: {
          :summary => "#{registration.service_role.full_name} Registration for #{registration.applicant_name} <#{registration.applicant_email}>",
          :project => {key: Otis.config.jira.elevated_access_project},
          :labels => [registration.service_role.name],
          :issuetype => {id: EA_REGISTRATION_ISSUETYPE_ID},
          EA_REGISTRATION_LINK_FIELD => submit_url,
          EA_REGISTRATION_EA_TYPE_FIELD => {value: registration.service_role.name},
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

    # After registrant has visited URL and clicked the button (we have a `registration.submitted` value):
    def submit!
      fields = {
        fields: {
          EA_REGISTRATION_EA_WORKFLOW_FIELD => {id: EA_REGISTRATION_SUBMITTED_WORKFLOW_ID}
        }
      }
      issue.save fields
      internal_comment!(issue: issue, comment: "registration submitted by #{registration.applicant_email}")
      transition_to! "Consulting with staff"
    end

    # Called when new ht_user is created from registration by HathiTrust staff.
    def approve!
      fields = {
        fields: {
          EA_REGISTRATION_EA_WORKFLOW_FIELD => {id: EA_REGISTRATION_APPROVED_WORKFLOW_ID}
        }
      }
      issue.save fields
      internal_comment!(issue: issue, comment: "registration approved for #{registration.applicant_email}")
      transition_to! "Waiting for support"
    end

    # Search for the issue's available transitions to find a destination status
    # case-insensitively matching the provided name, and transition to it.
    def transition_to!(name)
      # There's just so much we can do with NullClient
      return unless Rails.env.production?

      all_transitions = issue.transitions.all
      transition = all_transitions.find do |trans|
        trans.to.name.downcase == name.downcase
      end
      if transition.nil?
        raise "could not find #{name} in #{all_transitions.collect { |trans| trans.to.name }}"
      end
      issue.transitions.build.save!(transition: {id: transition.id})
    end
  end
end
