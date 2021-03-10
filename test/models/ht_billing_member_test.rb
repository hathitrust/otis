# frozen_string_literal: true

require 'test_helper'
class HTBillingMemberTest < ActiveSupport::TestCase
  test 'can persist an HTBillingMember' do
    inst = build(:ht_billing_member)
    inst.save
    assert(inst.persisted?)
  end

  test 'can persist billing entity fields' do
    inst = create(:ht_billing_member)
    persisted = HTBillingMember.first

    %i[inst_id weight oclc_sym marc21_sym country_code status].each do |field|
      assert_equal(inst.public_send(field), persisted.public_send(field))
    end
  end

  test 'can get the institution information' do
    inst = create(:ht_institution)
    billing_inst = inst.ht_billing_member

    assert_equal(inst.name, billing_inst.ht_institution.name)
  end
end
