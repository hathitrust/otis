# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'

class SAMLMetadata
  MET_ENDPOINT = 'https://met.refeds.org/met/entity'

  def self.metadata_for(entity_id)
    # make sure this is a parseable URI, then URI escape it to avoid path
    # traversal / query injection
    safe_entity_id = URI.encode_www_form_component(URI(entity_id).to_s)
    URI.open("#{MET_ENDPOINT}/#{safe_entity_id}?viewxml=true")
  end

  def initialize(entity_id, data: SAMLMetadata.metadata_for(entity_id))
    @entity_id = entity_id
    @doc = Nokogiri::XML(data)
  end

  def name
    @doc.xpath('//mdui:DisplayName|//md:organizationDisplayName|//md:OrganizationName').first.text
  end

  def scopes
    @doc.xpath('//md:IDPSSODescriptor/md:Extensions/shibmd:Scope').map(&:text)
  end

  def domain
    scopes.first
  end

  def domain_base
    domain.split('.').first
  end
end
