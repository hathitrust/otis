# frozen_string_literal: true

namespace :otis do
  desc <<~DESC
    Creates ht_institutions.tsv (inst_id -> name)
    and ht_saml_entity_ids.tsv (entityID -> name)
    and copies them to Otis.config.export_files_directory
    (public/ for the purposes of testing and development,
    see config/settings.yml).
  DESC
  task institutions_export: :environment do
    ie = Otis::InstitutionsExport.new
    Dir.mktmpdir do |d|
      ht_institutions_temp = File.join(d, Otis.config.ht_institutions_file)
      ht_saml_entity_ids_temp = File.join(d, Otis.config.ht_saml_entity_ids_file)
      File.write(ht_institutions_temp, ie.instid_data)
      File.write(ht_saml_entity_ids_temp, ie.entityid_data)
      FileUtils.cp(ht_institutions_temp, Otis.config.export_files_directory)
      FileUtils.cp(ht_saml_entity_ids_temp, Otis.config.export_files_directory)
    end
  end
end
