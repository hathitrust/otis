# frozen_string_literal: true

require "test_helper"

module Otis
  class InstitutionsExportTaskTest < ActiveSupport::TestCase
    def setup
      remove_generated_files
      create(:ht_institution)
    end

    def teardown
      remove_generated_files
    end

    def remove_generated_files
      if File.exist? ht_institutions_file
        FileUtils.rm ht_institutions_file
      end
      if File.exist? ht_saml_entity_ids_file
        FileUtils.rm ht_saml_entity_ids_file
      end
    end

    def ht_institutions_file
      File.join(Otis.config.export_files_directory, Otis.config.ht_institutions_file)
    end

    def ht_saml_entity_ids_file
      File.join(Otis.config.export_files_directory, Otis.config.ht_saml_entity_ids_file)
    end

    test "task writes the expected files" do
      Rake::Task["otis:institutions_export"].invoke
      assert File.exist? ht_institutions_file
      assert File.size(ht_institutions_file).positive?
      assert File.exist? ht_saml_entity_ids_file
      assert File.size(ht_saml_entity_ids_file).positive?
    end
  end
end
