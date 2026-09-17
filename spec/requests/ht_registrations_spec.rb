# frozen_string_literal: true

RSpec.describe "HTRegistrations", type: :request do
  before(:each) do
    HTRegistration.delete_all
    HTContact.delete_all
    HTInstitution.delete_all
  end

  describe "GET /ht_registrations" do
    it "succeeds" do
      sign_in!
      get ht_registrations_url
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /ht_registrations" do
    context "with valid parameters" do
      it "creates a new Registration and Contact, and redirects" do
        sign_in!
        attributes = build(:ht_registration).attributes.symbolize_keys
        attributes[:inst_id] = create(:ht_institution).inst_id
        expect {
          post ht_registrations_url, params: {ht_registration: attributes}
        }.to change(HTRegistration, :count).by(1)
          .and change(HTContact, :count).by(1)
        expect(response).to redirect_to(ht_registration_url(HTRegistration.last))
      end
    end
  end

  describe "PATCH /ht_registration" do
    context "with valid parameters" do
      let(:new_applicant_name) { "New Applicant Name" }
      let(:new_auth_rep_email) { "new_auth_rep@default.invalid" }
      let(:new_auth_rep_name) { "New Auth Rep" }
      let(:new_jira_ticket) { "EA-54321" }

      it "updates the Registration and Contact, and redirects" do
        registration = create(:ht_registration)
        sign_in!
        patch ht_registration_url registration, params: {
          ht_registration: {
            "applicant_name" => new_applicant_name,
            "auth_rep_email" => new_auth_rep_email,
            "auth_rep_name" => new_auth_rep_name,
            "jira_ticket" => new_jira_ticket
          }
        }
        registration.reload
        expect(response).to have_http_status(:redirect)
        # The Jira ticket will be assigned internally unless an EA ticket is submitted
        expect(registration.applicant_name).to eq(new_applicant_name)
        expect(registration.auth_rep_email).to eq(new_auth_rep_email)
        expect(registration.auth_rep_name).to eq(new_auth_rep_name)
        expect(registration.jira_ticket).to eq(new_jira_ticket)
        # Generic success notice
        expect(flash.notice).to match(/updated/)
        expect(HTContact.find_by(email: new_auth_rep_email)).not_to be nil
      end
    end
  end
end
