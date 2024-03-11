# frozen_string_literal: true

require "test_helper"

module Otis
  class InstitutionsExportTaskTest < ActiveSupport::TestCase
    def setup
      remove_generated_files
      5.times do
        create(:ht_institution)
      end
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
      assert File.exist? ht_saml_entity_ids_file
      ht_institutions_file_content = File.read(ht_institutions_file)
      ht_saml_entity_ids_file_content = File.read(ht_saml_entity_ids_file)
      HTInstitution.find_each do |inst|
        assert ht_institutions_file_content.include? [inst.inst_id, inst.name].join("\t")
        assert ht_saml_entity_ids_file_content.include? [inst.entityID, inst.name].join("\t")
      end
    end
  end
end
