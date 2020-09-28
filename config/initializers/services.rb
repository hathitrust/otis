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
if ENV['ASSET_PRECOMPILE'].blank?
  keycard_DB = Keycard::DB.initialize!
  keycard_DB.extension(:connection_validator)
  keycard_DB.pool.connection_validation_timeout = 300
  checkpoint_DB = Checkpoint::DB.initialize!
  checkpoint_DB.extension(:connection_validator)
  checkpoint_DB.pool.connection_validation_timeout = 300
end

Services = Canister.new

role_map = {admin: [:index, :show, :save, :edit, :create, :update],
            view: [:index, :show]}

Services.register(:checkpoint) do
  Checkpoint::Authority.new(credential_resolver: Checkpoint::Credential::RoleMapResolver.new(role_map),
                            resource_resolver: Checkpoint::Resource::Resolver.new)
end
