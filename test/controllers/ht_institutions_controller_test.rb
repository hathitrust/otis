# frozen_string_literal: true

require "test_helper"

class HTInstitutionsControllerIndexTest < ActionDispatch::IntegrationTest
  def setup
    @institution1 = create(:ht_institution)
    @institution2 = create(:ht_institution)
  end

  test "should get index" do
    sign_in!
    get ht_institutions_url
    assert_response :success
    assert_not_nil assigns(:enabled_institutions)
    assert_equal "index", @controller.action_name
    assert_match "Institutions", @response.body
    assert_match @institution1.inst_id, @response.body
    assert_match @institution2.inst_id, @response.body
  end

  test "index is well-formed HTML" do
    check_w3c_errs do
      sign_in!
      get ht_institutions_url
    end
  end

  test "enabled institutions separated from disabled ones" do
    enabled = create(:ht_institution, enabled: true)
    disabled = create(:ht_institution, enabled: false)

    sign_in!
    get ht_institutions_url

    assert_match(/Enabled Institutions.*#{enabled.inst_id}.*Other Institutions.*#{disabled.inst_id}/m, @response.body)
  end

  test "institutions sorted by name" do
    create(:ht_institution, name: "AAA University", enabled: true)
    create(:ht_institution, name: "ZZZ University", enabled: true)

    sign_in!
    get ht_institutions_url

    assert_match(/AAA.*ZZZ/m, @response.body)
  end

  test "as admin, shows link for new institution" do
    sign_in! username: "admin@default.invalid"
    get ht_institutions_url
    assert_match "institutions/new", @response.body
  end
end

class HTInstitutionsControllerShowTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution)
    @mfa_inst = create(:ht_institution, name: "MFA University", enabled: true,
      shib_authncontext_class: "https://refeds.org/profile/mfa")

    sign_in!
  end

  test "should get show page" do
    get ht_institution_url @inst
    assert_response :success
    assert_not_nil assigns(:institution)
    assert_equal "show", @controller.action_name
  end

  test "show page is well-formed HTML" do
    check_w3c_errs do
      sign_in!
      get ht_institution_url @inst
    end
  end

  test "shows institution name and id" do
    get ht_institution_url @inst
    assert_match @inst.inst_id, @response.body
    assert_match ERB::Util.html_escape(@inst.name), @response.body
  end

  test "Shows whoami link" do
    get ht_institution_url @inst
    assert_match(%r{/cgi/whoami}m, @response.body)
  end

  test "Without MFA auth context, suppresses whoami link with step-up MFA" do
    get ht_institution_url @inst
    assert_no_match(%r{authnContextClassRef=https://refeds.org/profile/mfa}m, @response.body)
  end

  test "With MFA auth context, shows whoami link with step-up MFA" do
    get ht_institution_url @mfa_inst
    assert_match(%r{authnContextClassRef=https://refeds.org/profile/mfa}m, @response.body)
  end

  test "shows billing member info" do
    get ht_institution_url @inst
    billing_member = @inst.ht_billing_member
    assert_match(/#{billing_member.oclc_sym}/, @response.body)
    assert_match(/#{billing_member.marc21_sym}/, @response.body)
  end

  test "shows contacts" do
    contact1 = create(:ht_contact, inst_id: @inst.id)
    contact2 = create(:ht_contact, inst_id: @inst.id)
    get ht_institution_url @inst
    assert_match(contact1.email, @response.body)
    assert_match(contact2.email, @response.body)
  end
end

class HTInstitutionsControllerCSVTest < ActionDispatch::IntegrationTest
  def setup
    @inst1 = HTInstitution.new(
      inst_id: "testinst", grin_instance: "b", name: "University of Testland",
      entityID: "https://testinst.edu/idp", enabled: 1
    )
    @inst1.save!
    @inst2 = create(:ht_institution, inst_id: "z")
  end

  test "export list of all institutions as CSV" do
    sign_in!
    get ht_institutions_url format: :csv
    assert_operator @response.body.lines.count, :>, 1
    assert_match(/^inst_id.*,name,.*,entityID/, @response.body.lines[0].strip)
    assert_match %r{^testinst,.*University of Testland.*https://testinst.edu/idp}, @response.body
  end
end

class HTInstitutionsControllerRolesTest < ActionDispatch::IntegrationTest
  def setup
    @inst = create(:ht_institution, inst_id: "whatever")
  end

  test "Staff user can see ht_institutions index and show page" do
    sign_in! username: "staff@default.invalid"
    get ht_institutions_url
    assert_response :success
    ht_institution_url @inst
    assert_response :success
  end

  test "Institutions-only user can see ht_institutions index and show page" do
    sign_in! username: "institution@default.invalid"
    get ht_institutions_url
    assert_response :success
    ht_institution_url @inst
    assert_response :success
  end

  test "Admin user can get edit page" do
    sign_in! username: "admin@default.invalid"
    get edit_ht_institution_url @inst
    assert_response :success
    assert_equal "edit", @controller.action_name
  end

  test "Admin user can create new" do
    sign_in! username: "admin@default.invalid"
    get new_ht_institution_url
    assert_response :success
    assert_equal "new", @controller.action_name
  end

  test "Staff user cannot create new" do
    sign_in! username: "staff@default.invalid"
    get new_ht_institution_url
    assert_response :forbidden
  end

  test "Staff user cannot edit" do
    sign_in! username: "staff@default.invalid"
    get edit_ht_institution_url @inst
    assert_response :forbidden
  end

  test "Staff user cannot update" do
    inst = create(:ht_institution, emergency_status: nil)
    sign_in! username: "staff@default.invalid"
    patch ht_institution_url inst, params: {"ht_institution" => {"emergency_status" => "anything"}}
    assert_response :forbidden

    inst.reload
    assert_nil HTInstitution.find(inst.inst_id).emergency_status
  end

  test "Staff user cannot create" do
    inst_params = attributes_for(:ht_institution)
    sign_in! username: "staff@default.invalid"
    post ht_institutions_url, params: {ht_institution: inst_params}

    assert_response :forbidden
  end
end

class HTInstitutionsControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "inst id is editable for new institution" do
    get new_ht_institution_url
    assert_select 'input[name="ht_institution[inst_id]"]'
  end

  test "us is selectable" do
    get new_ht_institution_url
    assert_select 'input[name="ht_institution[us]"]'
  end

  test "Can create" do
    inst_params = attributes_for(:ht_institution)
    inst_id = inst_params[:inst_id]
    post ht_institutions_url, params: {ht_institution: inst_params}

    assert_redirected_to ht_institution_url(inst_id)

    assert_not_nil(HTInstitution.find(inst_id))
  end

  test "marc org code editable for new institution" do
    get new_ht_institution_url
    assert_select 'input[name="ht_institution[ht_billing_member_attributes][marc21_sym]"]'
  end

  test "can create billing member and save marc code for new institution" do
    inst_params = attributes_for(:ht_institution)
    inst_id = inst_params[:inst_id]
    billing_params = attributes_for(:ht_billing_member)

    post ht_institutions_url, params: {
      ht_institution: {
        inst_id: inst_params[:inst_id],
        name: inst_params[:name],
        entityID: inst_params[:inst_id],
        domain: inst_params[:domain],
        us: inst_params[:us],
        enabled: inst_params[:enabled],
        ht_billing_member_attributes: {
          marc21_sym: billing_params[:marc21_sym],
          status: false
        }
      },
      create_billing_member: true
    }

    assert_redirected_to ht_institution_url(inst_id)
    assert_equal(HTInstitution.find(inst_id).ht_billing_member.marc21_sym, billing_params[:marc21_sym])
  end

  test "by default does not create billing member" do
    inst_params = attributes_for(:ht_institution)
    inst_id = inst_params[:inst_id]

    post ht_institutions_url, params: {
      ht_institution: {
        inst_id: inst_params[:inst_id],
        name: inst_params[:name],
        entityID: inst_params[:inst_id],
        domain: inst_params[:domain],
        us: inst_params[:us],
        enabled: inst_params[:enabled],
        ht_billing_member_attributes: {
          country_code: "us",
          weight: 0.0,
          status: false
        }
      }
    }

    assert_redirected_to ht_institution_url(inst_id)
    assert_nil(HTInstitution.find(inst_id).ht_billing_member)
  end

  test "logs creation" do
    inst_params = attributes_for(:ht_institution)
    inst_id = inst_params[:inst_id]
    post ht_institutions_url, params: {ht_institution: inst_params}
    assert_equal(inst_id, HTInstitution.find(inst_id).ht_logs.last.data["params"]["inst_id"])
  end

  test "shows error and reloads form on creation failure" do
    inst_params = attributes_for(:ht_institution)
    inst_params[:name] = nil
    post ht_institutions_url, params: {ht_institution: inst_params}
    assert_not_empty flash[:alert]
    assert_template "ht_institutions/new"
  end
end

class HTInstitutionsControllerEditTest < ActionDispatch::IntegrationTest
  setup do
    sign_in! username: "admin@default.invalid"
  end

  test "edit page is well-formed HTML" do
    check_w3c_errs do
      inst = create(:ht_institution)
      get edit_ht_institution_url inst
    end
  end

  test "Editable fields present" do
    inst = create(:ht_institution)
    get edit_ht_institution_url(inst)

    editable_fields = %w[name domain entityID mapto_inst_id grin_instance
      shib_authncontext_class allowed_affiliations
      emergency_status]
    editable_fields.each do |ef|
      assert_match(/name="ht_institution\[#{ef}\]"/, @response.body)
    end
  end

  test "Billing member fields present for inst with no billing member" do
    inst = create(:ht_institution, ht_billing_member: nil)
    get edit_ht_institution_url(inst)
    assert_match(/name="ht_institution\[ht_billing_member_attributes\]\[marc21_sym\]"/, @response.body)
  end

  test "Can update emergency status" do
    new_status = "^(member)@university.invalid"
    inst = create(:ht_institution, emergency_status: nil)
    patch ht_institution_url inst, params: {"ht_institution" => {"emergency_status" => new_status}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_institution_path(inst)
    follow_redirect!

    assert_match new_status, @response.body
    assert_equal new_status, HTInstitution.find(inst.inst_id).emergency_status
  end

  test "Blank emergency status sets null" do
    inst = create(:ht_institution, emergency_status: "^(member)@university.invalid")
    patch ht_institution_url inst, params: {"ht_institution" => {"emergency_status" => ""}}

    assert_response :redirect
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_institution_path(inst)
    follow_redirect!

    assert_nil HTInstitution.find(inst.inst_id).emergency_status
  end

  test "logs ETAS enabling with affiliation and time" do
    new_status = "^(member)@university.invalid"
    inst = create(:ht_institution, emergency_status: nil)
    patch ht_institution_url inst, params: {"ht_institution" => {"emergency_status" => new_status}}

    log = HTInstitution.find(inst.inst_id).ht_logs.last

    assert_not_nil(log.time)
    assert_equal(new_status, log.data["params"]["emergency_status"])
  end

  test "can add billing member for institution without one" do
    inst = create(:ht_institution, ht_billing_member: nil)
    billing_member_params = attributes_for(:ht_billing_member)

    patch ht_institution_url inst, params: {
      ht_institution: {
        inst_id: inst.inst_id,
        ht_billing_member_attributes: billing_member_params
      },
      create_billing_member: true
    }

    assert_equal billing_member_params[:marc21_sym], HTInstitution.find(inst.inst_id).ht_billing_member.marc21_sym
  end

  test "by default does not add billing member for institution without one" do
    inst = create(:ht_institution, ht_billing_member: nil)
    billing_member_params = attributes_for(:ht_billing_member)

    patch ht_institution_url inst, params: {
      ht_institution: {
        inst_id: inst.inst_id,
        ht_billing_member_attributes: billing_member_params
      }
    }

    assert_nil HTInstitution.find(inst.inst_id).ht_billing_member
  end

  test "can edit billing fields" do
    inst = create(:ht_institution)

    patch ht_institution_url inst, params: {
      ht_institution: {
        inst_id: inst.inst_id,
        ht_billing_member_attributes: {
          country_code: "xx"
        }
      }
    }

    assert_equal "xx", HTInstitution.find(inst.inst_id).ht_billing_member.country_code
  end

  test "fails update with missing name" do
    inst = create :ht_institution
    patch ht_institution_url inst, params: {ht_institution: {"name" => nil}}

    assert_response :success
    assert_equal "update", @controller.action_name
    assert_not_empty flash[:alert]
  end
end
