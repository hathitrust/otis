# frozen_string_literal: true

require "jira-ruby"
unless Rails.env.production?
  require "webmock"
  WebMock.enable!
  #require "debug"
  #binding.break

  # Get data about any other issue always succeeds
  WebMock.stub_request(:get, %r{\Ahttps://hathitrust.atlassian.net/rest/api/2/issue/.*?}).
    to_return(
      status: 200,
      body: {"key" => "EA-1", "id" => "00000", "fields" => {}}.to_json,
      headers: {"Content-Type"=> ["application/json","charset=UTF-8"]}
    )
  
  # Updates are allowed for anything
  WebMock.stub_request(:put, %r{\Ahttps://hathitrust.atlassian.net/rest/api/2/issue/.*?}).
    to_return(status: 204, body: "", headers: {})

  # Creating an issue always succeeds and returns EA-1
  WebMock.stub_request(:post, "https://hathitrust.atlassian.net/rest/api/2/issue").
    to_return(
      status: 200,
      body: {"key" => "EA-1", "id" => "00000", "fields" => {}}.to_json,
      headers: {"Content-Type"=> ["application/json","charset=UTF-8"]}
    )
  WebMock.stub_request(:post, %r{\Ahttps://hathitrust.atlassian.net/rest/api/2/issue/.*?/comment}).
    to_return(status: 200, body: "", headers: {})
  
  # Any operation on EA-000 always fails
  # Ordered last so regex matchers above don't override it.
  WebMock.stub_request(:any, "https://hathitrust.atlassian.net/rest/api/2/issue/EA-000").
    to_return(status: 404, body: "", headers: {})
  
  #WebMock.after_request { |req, res| puts "AHOY #{res.inspect}" }
end

module Otis
  class JiraClient
    unless Rails.env.production?
      DEFAULT_TICKET = "EA-1"
      BOGUS_TICKET = "EA-000"
    end
    INTERNAL_COMMENT_PROPERTIES = [
      {"key" => "sd.public.comment", "value" => {"internal" => true}}
    ].freeze
    JIRA_BASE_URL = URI.join(Otis.config.jira.site, "/browse/").to_s.freeze

    def self.jira_url(ticket)
      JIRA_BASE_URL + ticket
    end

    def initialize
      jira_credentials = Rails.application.credentials.jira || {username: "", password: ""}
      @client = JIRA::Client.new({
        username: jira_credentials[:username],
        password: jira_credentials[:password],
        site: Otis.config.jira.site,
        context_path: Otis.config.jira.context_path,
        auth_type: :basic,
        http_debug: true
      })
    end

    # Returns JIRA::Resource::Issue if it exists, otherwise nil.
    # FIXME: this should probably fail more noisily since we are relying on the Otis-Jira
    # communication in order to communicate with registrant.
    def find(issue)
      puts "FIND #{issue}"
      iss = @client.Issue.find issue
      puts "ISSUE #{iss}"
      iss
    end

    # Example:
    #   internal_comment! issue: find("EA-33"), comment: "This is a comment"
    def internal_comment!(issue:, comment:)
      issue.comments.build.save! body: comment, properties: INTERNAL_COMMENT_PROPERTIES
    end
  end
end
