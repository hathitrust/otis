# frozen_string_literal: true

require 'test_helper'

class HTInstitutionLogTest < ActiveSupport::TestCase
  def setup
    @inst = create(:ht_institution)
    @log_data = { 'foo' => 'bar', 'baz' => 'quux' }
    @log_entry = HTInstitutionLog.new(ht_institution: @inst, data: @log_data)
  end

  test 'can construct a log entry for a institution' do
    assert(@log_entry)
  end

  test 'can round-trip data for a log entry' do
    assert_equal @log_data, @log_entry.data
  end

  test 'can access persisted log data via institution' do
    @log_entry.save
    assert_equal @log_data, @inst.ht_institution_log.first.data
  end

  test 'is not valid without data' do
    log_entry = HTInstitutionLog.new(ht_institution: @inst)
    assert_not log_entry.valid?
  end

  test 'has a time by default' do
    assert @log_entry.time
  end
end
