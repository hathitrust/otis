# frozen_string_literal: true

RSpec.describe Otis::RegistrationMover do
  let(:fake_id) { fake_shib_id }
  let(:fake_env) { {"HTTP_X_REMOTE_USER" => fake_id}.to_json }

  describe "#ht_user" do
    # Note: `describe` blocks at this level are alphabetized by target `ht_user` attribute
    # or behavior.
    # Attributes that are just copied from registration to user do not necessarily have
    # tests unless they were added to address a bug or change request.
    describe "access" do
      [:ssdproxy, :resource_sharing].each do |role|
        it "#{role} role gets 'normal' access" do
          registration = create(:ht_registration, role: role, env: fake_env)
          expect(described_class.new(registration).ht_user.access).to eq "normal"
        end
      end

      (HTUser::ROLES - [:ssdproxy, :resource_sharing]).each do |role|
        it "#{role} role gets 'total' access" do
          registration = create(:ht_registration, role: role, env: fake_env)
          expect(described_class.new(registration).ht_user.access).to eq "total"
        end
      end
    end

    describe "activitycontact" do
      it "maps from contact_info" do
        registration = create(:ht_registration, contact_info: "contact_info@default.invalid")
        expect(described_class.new(registration).ht_user.activitycontact).to eq "contact_info@default.invalid"
      end
    end

    describe "identity_provider/inst_id" do
      it "maps entityID to identity_provider and copies inst_id" do
        inst = create(:ht_institution)
        registration = create(:ht_registration, inst_id: inst.inst_id, env: fake_env)
        ht_user = described_class.new(registration).ht_user
        expect(ht_user.identity_provider).to eq(inst.entityID)
        expect(ht_user.inst_id).to eq(inst.inst_id)
      end
    end

    describe "iprestrict/mfa" do
      context "with MFA-enabled institution" do
        it "creates MFA-enabled user with no IP restriction" do
          mfa_inst = create(:ht_institution, shib_authncontext_class: "https://refeds.org/profile/mfa")
          registration = create(:ht_registration, inst_id: mfa_inst.inst_id, env: fake_env)
          ht_user = described_class.new(registration).ht_user
          expect(ht_user.mfa?).to eq(true)
          expect(ht_user.iprestrict).to eq(nil)
        end
      end

      context "with non-MFA-enabled institution" do
        context "with MFA addendum" do
          it "creates non-MFA-enabled user with IP restriction wildcard" do
            non_mfa_inst = create(:ht_institution, shib_authncontext_class: nil)
            registration = create(
              :ht_registration,
              mfa_addendum: true,
              inst_id: non_mfa_inst.inst_id,
              env: fake_env
            )
            ht_user = described_class.new(registration).ht_user
            expect(ht_user.mfa?).to eq(false)
            expect(ht_user.iprestrict).to eq(["any"])
          end
        end

        context "without MFA addendum" do
          it "creates non-MFA-enabled user with single IP restriction" do
            non_mfa_inst = create(:ht_institution, shib_authncontext_class: nil)
            registration = create(
              :ht_registration,
              mfa_addendum: false,
              inst_id: non_mfa_inst.inst_id,
              env: fake_env
            )
            ht_user = described_class.new(registration).ht_user
            expect(ht_user.mfa?).to eq(false)
            expect(ht_user.iprestrict).to eq([registration.ip_address])
          end
        end
      end
    end

    describe "userid" do
      it "uses downcased shibboleth id for userid" do
        registration = create(:ht_registration, env: fake_env)
        expect(described_class.new(registration).ht_user.userid).to eq(fake_id.downcase)
      end

      context "with umich IDP" do
        context "with friend account (non-umich user)" do
          it "uses email for userid" do
            email = Faker::Internet.email
            env = {
              "HTTP_X_REMOTE_USER" => "https://shibboleth.umich.edu/idp/shibboleth!http://www.hathitrust.org/shibboleth-sp!gobbledygook",
              "HTTP_X_SHIB_IDENTITY_PROVIDER" => "https://shibboleth.umich.edu/idp/shibboleth",
              "HTTP_X_SHIB_MAIL" => email
            }.to_json
            registration = create(:ht_registration, env: env)
            expect(described_class.new(registration).ht_user.userid).to eq(email)
          end
        end

        context "without friend account (umich user)" do
          it "uses uniqname for userid" do
            uniqname = Faker::Internet.username
            env = {
              "HTTP_X_REMOTE_USER" => "https://shibboleth.umich.edu/idp/shibboleth!http://www.hathitrust.org/shibboleth-sp!gobbledygook",
              "HTTP_X_SHIB_UMICHCOSIGNFACTOR" => "UMICH.EDU",
              "HTTP_X_SHIB_IDENTITY_PROVIDER" => "https://shibboleth.umich.edu/idp/shibboleth",
              "HTTP_X_SHIB_EDUPERSONPRINCIPALNAME" => "#{uniqname}@umich.edu"
            }.to_json
            registration = create(:ht_registration, env: env)
            expect(described_class.new(registration).ht_user.userid).to eq(uniqname)
          end
        end
      end
    end

    describe "with an existing `ht_user`" do
      it "merges in new fields" do
        old_inst = create(:ht_institution)
        new_inst = create(:ht_institution, :mfa)
        existing_user = create(:ht_user, inst_id: old_inst.inst_id, role: "crms")
        registration = create(
          :ht_registration,
          applicant_email: existing_user.email,
          inst_id: new_inst.inst_id,
          role: "ssdproxy",
          mfa_addendum: true,
          env: {"HTTP_X_REMOTE_USER" => existing_user.email}.to_json
        )
        new_user = described_class.new(registration).ht_user
        expect(new_user.persisted?).to eq(true)
        expect(new_user).to eq(existing_user.reload)
        expect(new_user.inst_id).to eq(new_inst.inst_id)
        expect(new_user.role).to eq("ssdproxy")
      end
    end
  end
end
