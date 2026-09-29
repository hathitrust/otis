# frozen_string_literal: true

RSpec.describe Otis::JiraClient::Registration do
  let(:registration) { HTRegistration.new(role: :resource_sharing) }
  let(:client) { described_class.new(registration) }

  describe "#ea_field_summary" do
    it "uses the service role's full name" do
      expect(client.ea_field_summary).to match(/Resource Sharing/)
    end
  end

  describe "#ea_labels" do
    it "uses the service role's short name" do
      expect(client.ea_labels).to eq(["RS"])
    end
  end

  describe "#ea_type" do
    it "uses the service role's short name" do
      expect(client.ea_type).to eq({value: "RS"})
    end
  end
end
