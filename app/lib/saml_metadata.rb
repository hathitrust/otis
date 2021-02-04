require 'nokogiri'
require 'open-uri'


class SAMLMetadata

  MET_ENDPOINT = 'https://met.refeds.org/met/entity'

  def self.metadata_for(entityID)
    # make sure this is a parseable URI, then URI escape it to avoid path
    # traversal / query injection
    safe_entityID = URI.encode(URI(entityID).to_s)
    URI.open("#{MET_ENDPOINT}/#{safe_entityID}?viewxml=true")
  end

  def initialize(entityID, data: SAMLMetadata.metadata_for(entityID))
    @entityID = entityID
    @doc = Nokogiri::XML(data)
  end

  def name
    @doc.xpath("//mdui:DisplayName|//md:organizationDisplayName|//md:OrganizationName").first.text
  end

  def scopes
    @doc.xpath("//md:IDPSSODescriptor/md:Extensions/shibmd:Scope").map { |n| n.text }
  end

  def domain
    scopes.first
  end

  def domain_base
    domain.split(".").first
  end

end
