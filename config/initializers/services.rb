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

unless Checkpoint::DB.connected?
  if Checkpoint::DB.conn_opts.empty?
    Checkpoint::DB.connect!(db: Sequel.sqlite)
    Checkpoint::DB.migrate!
  end
end
Checkpoint::DB.initialize!

Services = Canister.new

role_map = {admin: [:index, :show, :save, :edit, :create, :update],
            staff: [:index, :show],
            institution: [:index, :show]}

Services.register(:checkpoint) do
  Checkpoint::Authority.new(#agent_resolver: ActorAgentResolver.new,
                            credential_resolver: Checkpoint::Credential::RoleMapResolver.new(role_map),
                            resource_resolver: Checkpoint::Resource::Resolver.new)
end

# Initialize the Checkpoint database with admin and staff users, for compatibility with
# the existing list in the production config.
#
# Checkpoint grant! allows identical database entries, hence the call
# to permits? to try to avoid filling the DB with duplicate entries.
# However, Checkpoint permits? returns false with identical parameters
# to the subsequent call to grant!
Checkpoint::DB.db[:grants].delete
admin_role = Checkpoint::Credential::Role.new(:admin)
staff_role = Checkpoint::Credential::Role.new(:staff)
institution_role = Checkpoint::Credential::Role.new(:institution)
res_wildcard = Checkpoint::Resource::AllOfAnyType.new
res_inst = Checkpoint::Resource.new(OpenStruct.new(id: :ht_institutions))
Otis.config.users.each do |u|
  agent = Checkpoint::Agent::Token.new('user', u)
  unless Services.checkpoint.permits?(agent, admin_role, res_wildcard)
    Services.checkpoint.grant!(agent, admin_role, res_wildcard)
  end
end
Otis.config.staff.each do |u|
  agent = Checkpoint::Agent::Token.new('user', u)
  unless Services.checkpoint.permits?(agent, staff_role, res_wildcard)
    Services.checkpoint.grant!(agent, staff_role, res_wildcard)
  end
end
Otis.config.institution.each do |u|
  agent = Checkpoint::Agent::Token.new('user', u)
  unless Services.checkpoint.permits?(agent, institution_role, res_inst)
    Services.checkpoint.grant!(agent, staff_role, res_inst)
  end
end

grants = Checkpoint::DB[:grants].map do |grant|
  "#{grant[:agent_token]}\t#{grant[:credential_token]}\t#{grant[:resource_token]}"
end
puts grants.join("\n")
puts '========== END =========='
