# frozen_string_literal: true

# Webmock for Jira testing
require "webmock"
WebMock.enable!
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ["chrome-server:4444"]
)

def fixture(name)
  File.join(__dir__, "fixtures", name)
end

EXISTING_TICKET = "EA-1"
NONEXISTENT_TICKET = "EA-0"

# Get data about any other issue always succeeds
WebMock.stub_request(:get, %r{https://hathitrust.atlassian.net/rest/api/2/issue/.*?})
  .to_return(
    status: 200,
    body: File.read(fixture("jira_issue.json")),
    headers: {"Content-Type" => ["application/json", "charset=UTF-8"]}
  )

# Updates are allowed for anything
WebMock.stub_request(:put, %r{https://hathitrust.atlassian.net/rest/api/2/issue/.*?})
  .to_return(status: 204, body: "", headers: {})

# Creating an issue always succeeds and returns EA-1
WebMock.stub_request(:post, "https://hathitrust.atlassian.net/rest/api/2/issue")
  .to_return(
    status: 200,
    body: File.read(fixture("jira_issue.json")),
    headers: {"Content-Type" => ["application/json", "charset=UTF-8"]}
  )

WebMock.stub_request(:get, %r{https://hathitrust.atlassian.net/rest/api/2/issue/.*?/transitions\?expand=transitions.fields})
  .to_return(
    status: 200,
    body: File.read(fixture("jira_transitions.json")),
    headers: {"Content-Type" => ["application/json", "charset=UTF-8"]}
  )

# Transition submit
WebMock.stub_request(:post, %r{https://hathitrust.atlassian.net/rest/api/2/issue/.*?/transitions})
  .to_return(status: 200, body: "", headers: {})

WebMock.stub_request(:post, %r{https://hathitrust.atlassian.net/rest/api/2/issue/.*?/comment})
  .to_return(status: 200, body: "", headers: {})

# Any operation on EA-0 always fails
# Ordered last so regex matchers above don't override it.
WebMock.stub_request(:any, "https://hathitrust.atlassian.net/rest/api/2/issue/EA-0")
  .to_return(status: 404, body: "", headers: {})

# WebMock.after_request { |req, res| puts "AHOY\nREQ #{req.inspect}\nRES #{res.inspect}" }
