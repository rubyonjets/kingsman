# frozen_string_literal: true

module Kingsman
  module Controllers
    # Create url helpers to be used with resource/scope configuration. Acts as
    # proxies to the generated routes created by kingsman.
    # Resource param can be a string or symbol, a class, or an instance object.
    # Example using a :user resource:
    #
    #   new_session_path(:user)      => new_user_session_path
    #   session_path(:user)          => user_session_path
    #   destroy_session_path(:user)  => destroy_user_session_path
    #
    #   new_password_path(:user)     => new_user_password_path
    #   password_path(:user)         => user_password_path
    #   edit_password_path(:user)    => edit_user_password_path
    #
    #   new_confirmation_path(:user) => new_user_confirmation_path
    #   confirmation_path(:user)     => user_confirmation_path
    #
    # Those helpers are included by default to ActionController::Base.
    #
    # Keeping interesting note about how Rails routes work.
    #
    # In case you want to add such helpers to another class, you can do
    # that as long as this new class includes both url_helpers and
    # mounted_helpers. Example:
    #
    #     include Rails.application.routes.url_helpers
    #     include Rails.application.routes.mounted_helpers
    #
    module UrlHelpers
      def self.remove_helpers!
        self.instance_methods.map(&:to_s).grep(/_(url|path)$/).each do |method|
          remove_method method
        end
      end

      def self.generate_helpers!(routes = nil)
        routes ||= begin
          mappings = Kingsman.mappings.values.map(&:used_helpers).flatten.uniq
          Kingsman::URL_HELPERS.slice(*mappings)
        end

        routes.each do |module_name, actions|
          [:path, :url].each do |path_or_url|
            actions.each do |action|
              action = action ? "#{action}_" : ""
              method = :"#{action}#{module_name}_#{path_or_url}"

              define_method method do |resource_or_scope, *args|
                scope = Kingsman::Mapping.find_scope!(resource_or_scope)
                router_name = Kingsman.mappings[scope].router_name
                context = router_name ? send(router_name) : _kingsman_route_context
                method_name = "#{action}#{scope}_#{module_name}_#{path_or_url}"
                context.send(method_name, *args)
              end
            end
          end
        end
      end

      generate_helpers!(Kingsman::URL_HELPERS)

      private

      def _kingsman_route_context
        @_kingsman_route_context ||= send(Kingsman.available_router_name)
      end
    end
  end
end
