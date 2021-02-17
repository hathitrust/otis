require "rails"

Rails.application.config.after_initialize do
  # https://stackoverflow.com/a/44013695
  if defined?(::Rails::Server)
    Keycard::DB.db.extension(:connection_validator)
    Keycard::DB.db.pool.connection_validation_timeout = 300
    Checkpoint::DB.db.extension(:connection_validator)
    Checkpoint::DB.db.pool.connection_validation_timeout = 300
  end
end
