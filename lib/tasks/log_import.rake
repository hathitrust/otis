# frozen_string_literal: true

namespace :otis do
  desc <<~DESC
    Imports latest batch of imgsrv download logs from ulib-logs and
    inserts the relevant entries (ssdproxy user) into the
    reports_downloads_ssdproxy table
  DESC
  task log_import: :environment do
    Otis::LogImporter.new.run
  end
end
