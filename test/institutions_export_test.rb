# frozen_string_literal: true

require "test_helper"

module Otis
  class InstitutionsExportTest < ActiveSupport::TestCase
    test "create functional InstitutionsExport" do
      ie = InstitutionsExport.new
      assert_not_nil ie
      assert_not_nil ie.institutions
    end
  end
end
