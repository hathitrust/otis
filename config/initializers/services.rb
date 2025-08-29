# frozen_string_literal: true

require "rails"
require "checkpoint"
require "keycard"
require "canister"
require "maxmind/geoip2"

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

Services = Canister.new

role_map = {admin: [:create, :destroy, :edit, :index, :new, :save, :show, :update, :preview, :mail, :approve],
            view: [:index, :show]}

Services.register(:checkpoint) do
  Checkpoint::Authority.new(
    credential_resolver: Checkpoint::Credential::RoleMapResolver.new(role_map),
    resource_resolver: Checkpoint::Resource::Resolver.new
  )
end

Services.register(:whois) { Whois::Client.new }

Services.register(:geoip) { MaxMind::GeoIP2::Reader.new(database: Otis.config.geoip_path) }
