# frozen_string_literal: true

require "test_helper"

module Otis
  class InstitutionsExportTest < ActiveSupport::TestCase
    test "create functional InstitutionsExport" do
      ie = InstitutionsExport.new
      assert_not_nil ie
      assert_not_nil ie.enabled_institutions
      assert_not_nil ie.enabled_for_login_institutions
    end
  end
end
