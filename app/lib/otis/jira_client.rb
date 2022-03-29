# frozen_string_literal: true

require "jira-ruby"

module Otis
  class JiraClient
    COMMENT_TEMPLATES = {
      registration_sent: "OTIS status update: registration e-mail sent to __USER__.",
      registration_received: "OTIS status update: registration submitted by __USER__.",
      registration_finished: "OTIS status update: registration finished for __USER__."
    }.freeze

    COMMENT_PROPERTIES = [
      {"key" => "sd.public.comment", "value" => {"internal" => true}}
    ].freeze

    def self.comment(template:, user:)
      COMMENT_TEMPLATES[template].gsub("__USER__", user)
    end

    def self.create_client
      if Rails.env.production?
        # :nocov:
        JIRA::Client.new({
          username: Rails.application.credentials.jira[:username],
          password: Rails.application.credentials.jira[:password],
          site: Otis.config.jira.site,
          context_path: Otis.config.jira.context_path,
          auth_type: :cookie,
          use_ssl: true,
          use_cookies: true
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
    def find(issue)
      @client.Issue.find issue
    rescue JIRA::HTTPError => _e
      nil
    end

    # Example:
    #   comment! issue: "HTS-33", comment: "This is a comment"
    def comment!(issue:, comment:)
      issue_obj = find issue
      return if issue_obj.nil?

      issue_obj.comments.build.save! body: comment, properties: COMMENT_PROPERTIES
    end

    # Fake JIRA::Client used outside production. Responds to most methods by returning self.
    class NullClient
      def method_missing(method_name, *arguments, &block)
        self
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end

    private_constant :NullClient
  end
end
