# frozen_string_literal: true

module Kingsman
  module Strategies
    # Base strategy for Kingsman. Responsible for verifying correct scope and mapping.
    class Base < ::Warden::Strategies::Base
      # Whenever CSRF cannot be verified, we turn off any kind of storage
      def store?
        !env["kingsman.skip_storage"]
      end

      # Checks if a valid scope was given for kingsman and find mapping based on this scope.
      def mapping
        @mapping ||= begin
          mapping = Kingsman.mappings[scope]
          raise "Could not find mapping for #{scope}" unless mapping
          mapping
        end
      end
    end
  end
end
