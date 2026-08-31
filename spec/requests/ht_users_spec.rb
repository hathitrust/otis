# frozen_string_literal: true

RSpec.describe "HTUsers", type: :request do
  before(:each) do
    HTUser.delete_all
    HTContact.delete_all
    HTInstitution.delete_all
  end

  describe "GET /ht_users" do
    it "succeeds" do
      sign_in!
      get ht_users_url
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /ht_user" do
    context "with valid parameters" do
      let(:new_displayname) { "New Displayname" }
      let(:new_approver) { "new_approver@default.invalid" }
      let(:new_approver_name) { "New Approver" }

      it "updates the User and Contact, and redirects" do
        user = create(:ht_user)
        sign_in!
        patch ht_user_url user, params: {
          ht_user: {
            "displayname" => new_displayname,
            "approver" => new_approver,
            "approver_name" => new_approver_name
          }
        }
        user.reload
        expect(response).to have_http_status(:redirect)
        expect(user.displayname).to eq(new_displayname)
        expect(user.approver).to eq(new_approver)
        expect(user.approver_name).to eq(new_approver_name)
        # Generic success notice
        expect(flash.notice).to match(/updated/)
        expect(HTContact.find_by(email: new_approver)).not_to be nil
      end
    end

    context "with bogus Approver Name" do
      let(:new_displayname) { "New Displayname" }
      let(:new_approver_name) { "" }

      it "does not update User or Contact" do
        user = create(:ht_user)
        sign_in!
        patch ht_user_url user, params: {
          ht_user: {
            "displayname" => new_displayname,
            "approver_name" => new_approver_name
          }
        }
        user.reload
        expect(response).to have_http_status(:ok)
        expect(user.approver_name).not_to eq(new_approver_name)
        # Roll back the update on user when contact update fails.
        expect(user.displayname).not_to eq(new_displayname)
        expect(flash.alert).to match(/validation failed/i)
      end
    end
  end
end
