# frozen_string_literal: true

def assign_db(lhs, rhs)
  if rhs.is_a? String
    lhs.url = rhs
  elsif rhs.respond_to?(:has_key?)
    if rhs["url"]
      lhs.url = rhs["url"]
    else
      lhs.opts = rhs
    end
  end
end


assign_db(Keycard::DB.config, Otis.config.keycard.database)
assign_db(Checkpoint::DB.config, Otis.config.checkpoint.database)

Keycard::DB.config.readonly = true if Otis.config.keycard&.readonly
Keycard.config.access = Otis.config.keycard&.access || :direct

Rails.application.config.after_initialize do
  # https://stackoverflow.com/a/44013695
  if defined?(::Rails::Server)
    Keycard::DB.db.extension(:connection_validator)
    Keycard::DB.db.pool.connection_validation_timeout = 300
    Checkpoint::DB.db.extension(:connection_validator)
    Checkpoint::DB.db.pool.connection_validation_timeout = 300
  end
end

Services = Canister.new

role_map = {admin: [:index, :show, :save, :edit, :new, :create, :update],
            view: [:index, :show]}

Services.register(:checkpoint) do
  Checkpoint::Authority.new(credential_resolver: Checkpoint::Credential::RoleMapResolver.new(role_map),
                            resource_resolver: Checkpoint::Resource::Resolver.new)
end
