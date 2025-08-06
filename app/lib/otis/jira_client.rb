# frozen_string_literal: true

require "jira-ruby"

module Otis
  class JiraClient
    INTERNAL_COMMENT_PROPERTIES = [
      {"key" => "sd.public.comment", "value" => {"internal" => true}}
    ].freeze

    def self.create_client
      if Rails.env.production?
        # :nocov:
        JIRA::Client.new({
          username: Rails.application.credentials.jira[:username],
          password: Rails.application.credentials.jira[:password],
          site: Otis.config.jira.site,
          context_path: Otis.config.jira.context_path,
          auth_type: :basic,
          http_debug: true
        })
        # :nocov:
      else
        NullClient.new
      end
    end

    def initialize
      @client = self.class.create_client
    end

    # Returns JIRA::Resource::Issue if it exists, otherwise nil.
    # FIXME: this should probably fail more noisily since we are relying on the Otis-Jira
    # communication in order to communicate with registrant.
    def find(issue)
      @client.Issue.find issue
    rescue JIRA::HTTPError => _e
      nil
    end

    # Example:
    #   internal_comment! issue: find("EA-33"), comment: "This is a comment"
    def internal_comment!(issue:, comment:)
      issue.comments.build.save! body: comment, properties: INTERNAL_COMMENT_PROPERTIES
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
