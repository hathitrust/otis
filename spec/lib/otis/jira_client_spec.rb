# frozen_string_literal: true

RSpec.describe Otis::JiraClient do
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
end
