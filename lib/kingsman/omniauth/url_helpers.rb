# frozen_string_literal: true

module Kingsman
  module OmniAuth
    # Note: scope is at the end of the method name for Jets whereas it is at the beginning for Rails
    module UrlHelpers
      def omniauth_authorize_path(resource_or_scope, provider, *args)
        scope = Kingsman::Mapping.find_scope!(resource_or_scope)
        _kingsman_route_context.send("#{provider}_omniauth_authorize_#{scope}_path", *args)
      end

      def omniauth_authorize_url(resource_or_scope, provider, *args)
        scope = Kingsman::Mapping.find_scope!(resource_or_scope)
        _kingsman_route_context.send("#{provider}_omniauth_authorize_#{scope}_url", *args)
      end

      def omniauth_callback_path(resource_or_scope, provider, *args)
        scope = Kingsman::Mapping.find_scope!(resource_or_scope)
        _kingsman_route_context.send("#{provider}_omniauth_callback_#{scope}_path", *args)
      end

      def omniauth_callback_url(resource_or_scope, provider, *args)
        scope = Kingsman::Mapping.find_scope!(resource_or_scope)
        _kingsman_route_context.send("#{provider}_omniauth_callback_#{scope}_url", *args)
      end
    end
  end
end
