# frozen_string_literal: true

require 'test_helper'

class SAMLMetadataTest < ActiveSupport::TestCase
  TEST_ENTITY_ID = 'https://east.westland.test/idp/shibboleth'

  def test_metadata_path
    Rails.root.join('test', 'fixtures', 'test_metadata.xml')
  end

  def test_metadata
    SAMLMetadata.new(TEST_ENTITY_ID, data: File.read(test_metadata_path))
  end

  test 'loads metadata' do
    assert_not_nil test_metadata
  end

  test 'extracts the name' do
    assert_equal 'University of East Westland', test_metadata.name
  end

  test 'extracts all scopes' do
    assert_equal ['westland.test', 'east.westland.test'], test_metadata.scopes
  end

  test 'extracts the domain' do
    assert_equal 'westland.test', test_metadata.domain
  end

  test 'extracts the domain base' do
    assert_equal 'westland', test_metadata.domain_base
  end
end
