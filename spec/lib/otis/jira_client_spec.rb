# frozen_string_literal: true

RSpec.describe Otis::JiraClient do
  let(:client) { described_class.new }

  describe ".credentials" do
    it "provides a username and password" do
      expect(described_class.credentials[:username]).to be_a(String)
      expect(described_class.credentials[:password]).to be_a(String)
    end
  end

  describe ".credentials_path" do
    context "with OTIS_JIRA_CONFIG set" do
      it "uses the value in ENV" do
        test_path = "/test/path/to/jira.yml"
        ClimateControl.modify(OTIS_JIRA_CONFIG: test_path) do
          expect(described_class.credentials_path).to eq(test_path)
        end
      end
    end

    context "with OTIS_JIRA_CONFIG unset" do
      it "uses the default path" do
        ClimateControl.modify(OTIS_JIRA_CONFIG: nil) do
          expect(described_class.credentials_path).to match(/config\/jira.yml/)
        end
      end
    end
  end

  describe ".jira_url" do
    it "returns a URL with the provided ticket" do
      expect(described_class.jira_url("TEST_TICKET")).to start_with("https")
        .and match("TEST_TICKET")
    end
  end

  describe ".new" do
    it "creates #{described_class}" do
      expect(described_class.new).to be_a(described_class)
    end
  end

  describe "#find" do
    context "with a real ticket" do
      it "returns JIRA::Resource::Issue" do
        expect(
          client.find(EXISTING_TICKET)
        ).to be_a(JIRA::Resource::Issue)
      end
    end

    context "with a nonexistent ticket" do
      it "raises" do
        expect {
          client.find(NONEXISTENT_TICKET)
        }.to raise_error(JIRA::HTTPError)
      end
    end
  end

  describe "#internal_comment!" do
    it "does something" do
      expect(
        client.internal_comment!(
          issue: client.find(EXISTING_TICKET),
          comment: "this is a comment"
        )
      ).to eq(true)
    end
  end
end
