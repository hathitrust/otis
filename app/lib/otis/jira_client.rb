# frozen_string_literal: true

require "jira-ruby"
require "yaml"

module Otis
  class JiraClient
    INTERNAL_COMMENT_PROPERTIES = [
      {"key" => "sd.public.comment", "value" => {"internal" => true}}
    ].freeze
    JIRA_BASE_URL = URI.join(Otis.config.jira.site, "/browse/").to_s.freeze

    # Read YML file at OTIS_JIRA_CONFIG or config/jira.yml
    # and return a hash with :username and :password
    def self.credentials
      YAML.safe_load_file(credentials_path, symbolize_names: true)
    end

    # OTIS_JIRA_CONFIG or config/jira.yml
    def self.credentials_path
      ENV.fetch("OTIS_JIRA_CONFIG", Rails.root.join("config", "jira.yml").to_s)
    end

    def self.jira_url(ticket)
      JIRA_BASE_URL + ticket
    end

    def initialize
      credentials = self.class.credentials
      @client = JIRA::Client.new({
        username: credentials[:username],
        password: credentials[:password],
        site: Otis.config.jira.site,
        context_path: Otis.config.jira.context_path,
        auth_type: :basic,
        # `http_debug` can be useful to have in production, annoying noise in development/test.
        http_debug: Rails.env.production?
      })
    end

    # Returns JIRA::Resource::Issue if it exists, otherwise raises `JIRA::HTTPError`.
    def find(issue)
      @client.Issue.find issue
    end

    # Example:
    #   internal_comment! issue: find("EA-33"), comment: "This is a comment"
    # Returns true of false on success or failure
    def internal_comment!(issue:, comment:)
      issue.comments.build.save! body: comment, properties: INTERNAL_COMMENT_PROPERTIES
    end
  end
end
