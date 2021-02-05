# frozen_string_literal: true

require 'test_helper'

class SAMLMetadataTest < ActiveSupport::TestCase
  UMICH_ENTITY_ID = 'https://shibboleth.umich.edu/idp/shibboleth'

  def umich_metadata_path
    Rails.root.join('test', 'fixtures', 'umich_metadata.xml')
  end

  def umich_metadata
    SAMLMetadata.new(UMICH_ENTITY_ID, data: File.read(umich_metadata_path))
  end

  test 'loads metadata' do
    assert_not_nil umich_metadata
  end

  test 'extracts the name' do
    assert_equal 'University of Michigan', umich_metadata.name
  end

  test 'extracts all scopes' do
    assert_equal ['umich.edu', 'umd.umich.edu', 'flint.umich.edu', 'annarbor.umich.edu', 'dearborn.umich.edu'], umich_metadata.scopes
  end

  test 'extracts the domain' do
    assert_equal 'umich.edu', umich_metadata.domain
  end

  test 'extracts the domain base' do
    assert_equal 'umich', umich_metadata.domain_base
  end
end
