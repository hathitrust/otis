# frozen_string_literal: true

require 'test_helper'

class HTUserLogTest < ActiveSupport::TestCase
  def setup
    @user = create(:ht_user)
    @log_data = { 'foo' => 'bar', 'baz' => 'quux' }
    @log_entry = HTUserLog.new(ht_user: @user, data: @log_data)
  end

  test 'can construct a log entry for a user' do
    assert(@log_entry)
  end

  test 'can round-trip data for a log entry' do
    assert_equal @log_data, @log_entry.data
  end

  test 'can access persisted log data via user' do
    @log_entry.save
    assert_equal @log_data, @user.ht_user_log.first.data
  end

  test 'is not valid without data' do
    log_entry = HTUserLog.new(ht_user: @user)
    assert_not log_entry.valid?
  end

  test 'has a time by default' do
    assert @log_entry.time
  end
end
