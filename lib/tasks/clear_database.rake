# frozen_string_literal: true

namespace :otis do
  desc "Clears ht_repository and ht_web tables after system tests run"
  # System tests are currently seeded with Fakerized data.
  # This messes up the regular tests which expect empty tables.
  # bundle exec rake db:reset should work except of course Keycard has a hissy fit when you run it.
  task clear_database: :environment do
    ActiveRecord::Base.connection.execute("DELETE FROM ht_repository.ht_billing_members")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_repository.ht_institutions")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_repository.ht_users")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_repository.otis_contact_types")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_repository.otis_contacts")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_web.ht_counts")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_web.otis_approval_requests")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_web.otis_logs")
    ActiveRecord::Base.connection.execute("DELETE FROM ht_web.otis_registrations")
  end
end
