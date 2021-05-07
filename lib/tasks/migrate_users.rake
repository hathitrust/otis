# frozen_string_literal: true

# Initialize the Checkpoint database with admin and staff users, for compatibility with
# the existing list in the production config.
#
# Checkpoint grant! allows identical database entries, hence the call
# to permits? to try to avoid filling the DB with duplicate entries.
# However, Checkpoint permits? returns false with identical parameters
# to the subsequent call to grant!
namespace :otis do
  desc "Add grants to the Checkpoint DB from config entries"
  task migrate_users: :environment do
    require "checkpoint"
    Checkpoint::DB.initialize!
    Checkpoint::DB.db[:grants].delete
    admin_role = Checkpoint::Credential::Role.new(:admin)
    view_role = Checkpoint::Credential::Role.new(:view)
    res_wildcard = Checkpoint::Resource::AllOfAnyType.new
    if Otis.config.users.present?
      Otis.config.users.each do |u|
        agent = Checkpoint::Agent::Token.new("user", u)
        unless Services.checkpoint.permits?(agent, admin_role, res_wildcard)
          Services.checkpoint.grant!(agent, admin_role, res_wildcard)
        end
      end
    end
    if Otis.config.staff.present?
      Otis.config.staff.each do |u|
        agent = Checkpoint::Agent::Token.new("user", u)
        unless Services.checkpoint.permits?(agent, view_role, res_wildcard)
          Services.checkpoint.grant!(agent, view_role, res_wildcard)
        end
      end
    end
    if Otis.config.institution.present?
      res_inst = Checkpoint::Resource::AllOfType.new(:ht_institutions)
      Otis.config.institution.each do |u|
        agent = Checkpoint::Agent::Token.new("user", u)
        unless Services.checkpoint.permits?(agent, view_role, res_inst)
          Services.checkpoint.grant!(agent, view_role, res_inst)
        end
      end
    end
    grants = Checkpoint::DB[:grants].map do |grant|
      "#{grant[:agent_token]}\t#{grant[:credential_token]}\t#{grant[:resource_token]}"
    end
    puts grants.join("\n")
  end
end
