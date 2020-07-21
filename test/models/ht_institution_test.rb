# frozen_string_literal: true

require 'test_helper'

class HTInstitutionTest < ActiveSupport::TestCase
  def setup
    @enabled  = create(:ht_institution, enabled: true)
    @disabled = create(:ht_institution, enabled: false)
  end

  test 'validation passes' do
    assert build(:ht_institution).valid?
  end

  test 'enabled scope' do
    assert_equal HTInstitution.enabled.first.inst_id, @enabled.inst_id
  end

  test 'other scope' do
    assert_equal HTInstitution.other.first.inst_id, @disabled.inst_id
  end

  test 'correct Checkpoint resource_type and resource_id' do
    inst = build(:ht_institution, id: 'id')
    assert_equal inst.resource_type, :ht_institution
    assert_equal inst.resource_id, 'id'
  end
end
