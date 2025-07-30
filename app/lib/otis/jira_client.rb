# frozen_string_literal: true

require "jira-ruby"

module Otis
  class JiraClient
    include Rails.application.routes.url_helpers

    # ETT-220 TODO: this may be removed
    COMMENT_TEMPLATES = {
      registration_sent: "OTIS status update: registration e-mail sent to __USER__.",
      registration_received: "OTIS status update: registration submitted by __USER__.",
      registration_finished: "OTIS status update: registration finished for __USER__."
    }.freeze

    COMMENT_PROPERTIES = [
      {"key" => "sd.public.comment", "value" => {"internal" => true}}
    ].freeze

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

    def self.create_client
      if Rails.env.production?
        # :nocov:
        # Can set pass `http_debug: true` for a bit of debugging if needed
        JIRA::Client.new({
          username: Rails.application.credentials.jira[:username],
          password: Rails.application.credentials.jira[:password],
          site: Otis.config.jira.site,
          context_path: Otis.config.jira.context_path,
          auth_type: :basic
        })
        # :nocov:
      else
        NullClient.new
      end
    end

    def initialize(client: self.class.create_client)
      @client = client
    end

    # Returns JIRA::Resource::Issue if it exists, otherwise nil.
    def find(issue)
      @client.Issue.find issue
    rescue JIRA::HTTPError => _e
      nil
    end

    # Example:
    #   comment! issue: "EA-33", comment: "This is a comment"
    def comment!(issue:, comment:)
      issue_obj = find issue
      return if issue_obj.nil?

      issue_obj.comments.build.save! body: comment, properties: COMMENT_PROPERTIES
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

    def update_ea_ticket!(registration)
      issue = ea_issue(registration)
      issue.save(ea_fields(registration))
      if !has_ea_ticket?(registration)
        registration.jira_ticket = issue.key
      end
      Rails.logger.info "new or updated ticket for #{registration.applicant_email}: #{issue.key}"
    end

    # False if blank or GS, true if EA
    def has_ea_ticket?(registration)
      registration.jira_ticket&.start_with?(Otis.config.jira.elevated_access_project)
    end

    # If there's a GS ticket, or no ticket, in the registration, always create a new EA ticket.
    # If there's an EA ticket then we keep using that one.
    def ea_issue(registration)
      if has_ea_ticket?(registration)
        @client.Issue.find(registration.jira_ticket)
      else
        @client.Issue.build
      end
    end

    def ea_fields(registration)
      ea_type = ROLE_TO_REGISTRATION_TYPE[registration.role]
      data = {
        fields: {
          :summary => "#{ea_type} Registration for #{registration.applicant_email}",
          :description => "#{ea_type} Registration for <#{registration.applicant_email}>",
          :project => {key: Otis.config.jira.elevated_access_project},
          :labels => [ea_type],
          :issuetype => {id: EA_REGISTRATION_ISSUETYPE_ID},
          EA_REGISTRATION_LINK_FIELD => Rails.application.routes.url_helpers.finalize_url(registration.token, locale: nil),
          EA_REGISTRATION_EA_TYPE_FIELD => {value: ea_type},
          # MS will use this to kick off the email, don't set it here unless we want to send the email automatically
          # EA_REGISTRATION_EA_WORKFLOW_FIELD => {value: "Registration email pending"},
          EA_REGISTRATION_EMAIL_FIELD => registration.applicant_email
        }
      }
      if !has_ea_ticket?(registration)
        data[:fields][EA_REGISTRATION_GS_TICKET_FIELD] = registration.jira_ticket
      end
    end

    # Fake JIRA::Client used outside production. Responds to most methods by returning self,
    # which means NullClient.Issue => NullClient
    class NullClient
      def method_missing(method_name, *arguments, &block)
        self
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end

      def key
        "EA-0"
      end

      def find(ticket)
        if ticket == "does not exist"
          raise JIRA::HTTPError, "Does not exist"
        end
        self
      end
    end

    private_constant :NullClient
  end
end
