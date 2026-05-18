# frozen_string_literal: true

RSpec.describe Otis::JiraClient do
  describe ".credentials" do
    it "provides a username and password" do
      expect(described_class.credentials[:username]).to be_a(String)
      expect(described_class.credentials[:password]).to be_a(String)
    end
  end
end
