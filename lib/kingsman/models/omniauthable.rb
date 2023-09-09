# frozen_string_literal: true

require 'kingsman/omniauth'

module Kingsman
  module Models
    # Adds OmniAuth support to your model.
    #
    # == Options
    #
    # Oauthable adds the following options to +kingsman+:
    #
    #   * +omniauth_providers+: Which providers are available to this model. It expects an array:
    #
    #       kingsman :database_authenticatable, :omniauthable, omniauth_providers: [:twitter]
    #
    module Omniauthable
      extend ActiveSupport::Concern

      def self.required_fields(klass)
        []
      end

      module ClassMethods
        Kingsman::Models.config(self, :omniauth_providers)
      end
    end
  end
end
