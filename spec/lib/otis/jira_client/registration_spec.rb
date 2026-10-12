# frozen_string_literal: true

RSpec.describe Otis::JiraClient::Registration do
  let(:registration_ea) { HTRegistration.new(role: :resource_sharing, jira_ticket: "EA-1") }
  let(:registration_gs) { HTRegistration.new(role: :resource_sharing, jira_ticket: "GS-1") }
  let(:client_ea) { described_class.new(registration_ea) }
  let(:client_gs) { described_class.new(registration_gs) }

  describe ".new" do
    it "creates #{described_class}" do
      expect(client_ea).to be_a(described_class)
    end
  end

  describe "#ea_fields" do
    context "with a registration that only has a GS ticket" do
      it "includes the GS ticket custom field" do
        expect(client_gs.ea_fields[:fields]).to have_key(described_class::EA_REGISTRATION_GS_TICKET_FIELD)
      end
    end

    context "with a registration that already has an EA ticket" do
      it "does not include a GS ticket custom field" do
        expect(client_ea.ea_fields[:fields]).not_to have_key(described_class::EA_REGISTRATION_GS_TICKET_FIELD)
      end
    end
  end

  describe "#ea_field_summary" do
    it "uses the service role's full name" do
      expect(client_ea.ea_field_summary).to match(/Resource Sharing/)
    end
  end

  describe "#ea_field_labels" do
    it "uses the service role's short name" do
      expect(client_ea.ea_field_labels).to eq(["RS"])
    end
  end

  describe "#ea_field_type" do
    it "uses the service role's short name" do
      expect(client_ea.ea_field_type).to eq({value: "RS"})
    end
  end

  describe "#update_ea_ticket!" do
    context "with a registration that only has a GS ticket" do
      it "updates the registration's ticket and returns true" do
        result = client_gs.update_ea_ticket!
        expect(client_gs.registration.jira_ticket).to start_with("EA")
        expect(result).to eq(true)
      end
    end

    context "with a registration that already has an EA ticket" do
      it "returns false" do
        result = client_ea.update_ea_ticket!
        expect(result).to eq(false)
      end
    end
  end

  describe "#submit!" do
    it "does not raise an error" do
      expect {
        client_ea.submit!
      }.not_to raise_error
    end
  end

  describe "#approve!" do
    it "does not raise an error" do
      expect {
        client_ea.approve!
      }.not_to raise_error
    end
  end

  describe "#transition_to!" do
    it "raises if specified transition name is unavailable" do
      expect {
        client_ea.transition_to!("there is so such transition as this")
      }.to raise_error(/could not find transition/)
    end
  end
end
