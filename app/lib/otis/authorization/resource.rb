# frozen_string_literal: true

module Otis
  module Authorization
    module Resource
      def self.included(klass)
        klass.extend ClassMethods
      end

      module ClassMethods
        def to_resource
          Checkpoint::Resource::AllOfType.new to_s.underscore.to_sym
        end

        def to_resource_name
          to_s.underscore.to_sym
        end
      end

      def to_resource
        Checkpoint::Resource.new self
      end

      def resource_type
        self.class.to_resource_name
      end

      def resource_id
        id
      end
    end
  end
end
