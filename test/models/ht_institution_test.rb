# frozen_string_literal: true

require "test_helper"

class HTInstitutionTest < ActiveSupport::TestCase
  def setup
    @enabled = create(:ht_institution, enabled: true)
    @disabled = create(:ht_institution, enabled: false)
  end

  test "validation passes" do
    assert build(:ht_institution).valid?
  end

  test "enabled scope" do
    assert_equal HTInstitution.enabled.first.inst_id, @enabled.inst_id
  end

  test "other scope" do
    assert_equal HTInstitution.other.first.inst_id, @disabled.inst_id
  end

  test "correct Checkpoint resource_type and resource_id" do
    inst = build(:ht_institution, id: "id")
    assert_equal :ht_institution, inst.resource_type
    assert_equal "id", inst.resource_id
  end

  test "must have an inst id" do
    assert_not build(:ht_institution, inst_id: nil).valid?
  end

  test "must have a unique inst id" do
    inst = create(:ht_institution)
    assert_not build(:ht_institution, inst_id: inst.inst_id).valid?
  end

  test "must have a name" do
    assert_not build(:ht_institution, name: nil).valid?
  end

  test "must have an enabled value" do
    assert_not build(:ht_institution, enabled: nil).valid?
  end

  test "defaults mapto_instid to inst_id" do
    inst = build(:ht_institution, mapto_inst_id: nil)
    inst.save

    assert_equal(inst.inst_id, inst.mapto_inst_id)
  end

  test "sets template on save if entityid is set" do
    inst = build(:ht_institution, entityID: "urn:something")
    inst.save

    assert_equal("https://___HOST___/Shibboleth.sso/Login?entityID=urn:something&target=___TARGET___",
      inst.template)
  end
end

class HTInstitutionSAMLTest < ActiveSupport::TestCase
  TEST_ENTITY_ID = "https://east.westland.test/idp/shibboleth"

  def setup
    @inst = create(:ht_institution)
  end

  test "sets SAML metadata" do
    test_metadata_path = Rails.root.join("test", "fixtures", "test_metadata.xml")
    metadata = SAMLMetadata.new(TEST_ENTITY_ID, data: File.read(test_metadata_path))
    @inst.set_defaults_for_entity(TEST_ENTITY_ID, metadata)
    assert_equal TEST_ENTITY_ID, @inst.entityID
    assert_equal metadata.name, @inst.name
    assert_equal metadata.domain, @inst.domain
    assert_equal metadata.domain_base, @inst.inst_id
    assert_equal metadata.domain_base, @inst.mapto_inst_id
    metadata.scopes.each do |scope|
      assert_match scope, @inst.allowed_affiliations
    end
  end
end
