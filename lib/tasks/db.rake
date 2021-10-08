# frozen_string_literal: true

namespace :otis do
  namespace :db do
    # Copy db/schema.rb (our OTIS-specific database, repo version)
    # to db/otis_schema.rb if it does not already exist.
    # Then replace it with a dump of mariadb-test so the test DB can
    # be blown away and recreated.
    desc "Copy schema to local_schema and dump test DB to schema"
    task :prepare_local_schema do
      otis_schema = File.expand_path("db/otis_schema.rb", Rails.root)
      schema = File.expand_path("db/schema.rb", Rails.root)
      unless File.exist? otis_schema
        FileUtils.mv schema, otis_schema
        Rake::Task["db:schema:dump"].invoke
      end
    end

    desc "Load local_schema to extend test DB with OTIS tables"
    task :load_local_schema do
      otis_schema = File.expand_path("db/otis_schema.rb", Rails.root)
      load otis_schema
    end

    desc "Restore local_schema to schema for distribution"
    task :restore_schema do
      otis_schema = File.expand_path("db/otis_schema.rb", Rails.root)
      schema = File.expand_path("db/schema.rb", Rails.root)
      if File.exist? otis_schema
        FileUtils.mv otis_schema, schema
      end
    end
  end
end
