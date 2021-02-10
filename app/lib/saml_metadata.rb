# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'

class SAMLMetadata
  SAML_NAMESPACES = {
    shibmd: 'urn:mace:shibboleth:metadata:1.0',
    mdui: 'urn:oasis:names:tc:SAML:metadata:ui',
    md: 'urn:oasis:names:tc:SAML:2.0:metadata'
  }.freeze

  def self.metadata_for(entity_id)
    # make sure this is a parseable URI, then URI escape it to avoid path
    # traversal / query injection
    safe_entity_id = URI.encode_www_form_component(URI(entity_id).to_s)
    URI.open("#{Otis.config.met_entity_endpoint}/#{safe_entity_id}?viewxml=true")
  end

  def initialize(entity_id, data: SAMLMetadata.metadata_for(entity_id))
    @entity_id = entity_id
    @doc = Nokogiri::XML(data)
  end

  def name
    @doc.xpath('//mdui:DisplayName|//md:organizationDisplayName|//md:OrganizationName', SAML_NAMESPACES).first.text
  end

  def scopes
    @doc.xpath('//md:IDPSSODescriptor/md:Extensions/shibmd:Scope', SAML_NAMESPACES).map(&:text)
  end

  def domain
    scopes.first
  end

  def domain_base
    domain.split('.').first
  end
end
