# frozen_string_literal: true

module Kingsman
  module Controllers
    # Those helpers are convenience methods added to ApplicationController.
    module Helpers
      extend ActiveSupport::Concern
      include Kingsman::Controllers::SignInOut
      include Kingsman::Controllers::StoreLocation

      included do
        if respond_to?(:helper_method)
          helper_method :warden, :signed_in?, :kingsman_controller?
        end
      end

      # Define authentication filters and accessor helpers based on mappings.
      # These filters should be used inside the controllers as before_actions,
      # so you can control the scope of the user who should be signed in to
      # access that specific controller/action.
      # Example:
      #
      #   Roles:
      #     User
      #     Admin
      #
      #   Generated methods:
      #     authenticate_user!  # Signs user in or redirect
      #     authenticate_admin! # Signs admin in or redirect
      #     user_signed_in?     # Checks whether there is a user signed in or not
      #     admin_signed_in?    # Checks whether there is an admin signed in or not
      #     current_user        # Current signed in user
      #     current_admin       # Current signed in admin
      #     user_session        # Session data available only to the user scope
      #     admin_session       # Session data available only to the admin scope
      #
      #   Use:
      #     before_action :authenticate_user!  # Tell kingsman to use :user map
      #     before_action :authenticate_admin! # Tell kingsman to use :admin map
      #
      def self.define_helpers(mapping) #:nodoc:
        mapping = mapping.name

        class_eval <<-METHODS, __FILE__, __LINE__ + 1
          def authenticate_#{mapping}!(opts = {})
            opts[:scope] = :#{mapping}
            warden.authenticate!(opts) if !kingsman_controller? || opts.delete(:force)
          end

          def #{mapping}_signed_in?
            !!current_#{mapping}
          end

          def current_#{mapping}
            @current_#{mapping} ||= warden.authenticate(scope: :#{mapping})
          end

          def #{mapping}_session
            current_#{mapping} && warden.session(:#{mapping})
          end
        METHODS

        ActiveSupport.on_load(:jets_controller) do
          if respond_to?(:helper_method)
            helper_method "current_#{mapping}", "#{mapping}_signed_in?", "#{mapping}_session"
          end
        end
      end

      # The main accessor for the warden proxy instance
      def warden
        request.env['warden'] or raise MissingWarden
      end

      # Return true if it's a kingsman_controller. false to all controllers unless
      # the controllers defined inside kingsman. Useful if you want to apply a before
      # filter to all controllers, except the ones in kingsman:
      #
      #   before_action :my_filter, unless: :kingsman_controller?
      def kingsman_controller?
        is_a?(::KingsmanController)
      end

      # Set up a param sanitizer to filter parameters using strong_parameters. See
      # lib/kingsman/parameter_sanitizer.rb for more info. Override this
      # method in your application controller to use your own parameter sanitizer.
      def kingsman_parameter_sanitizer
        @kingsman_parameter_sanitizer ||= Kingsman::ParameterSanitizer.new(resource_class, resource_name, params)
      end

      # Tell warden that params authentication is allowed for that specific page.
      def allow_params_authentication!
        request.env["kingsman.allow_params_authentication"] = true
      end

      # The scope root url to be used when they're signed in. By default, it first
      # tries to find a resource_root_path, otherwise it uses the root_path.
      def signed_in_root_path(resource_or_scope)
        scope = Kingsman::Mapping.find_scope!(resource_or_scope)
        router_name = Kingsman.mappings[scope].router_name

        home_path = "#{scope}_root_path"

        context = router_name ? send(router_name) : self
        if context.respond_to?(home_path, true)
          context.send(home_path)
        elsif context.respond_to?(:root_path)
          context.root_path
        elsif respond_to?(:root_path)
          root_path
        else
          "/"
        end
      end

      # The default url to be used after signing in. This is used by all Kingsman
      # controllers and you can overwrite it in your ApplicationController to
      # provide a custom hook for a custom resource.
      #
      # By default, it first tries to find a valid resource_return_to key in the
      # session, then it fallbacks to resource_root_path, otherwise it uses the
      # root path. For a user scope, you can define the default url in
      # the following way:
      #
      #   get '/users' => 'users#index', as: :user_root # creates user_root_path
      #
      #   namespace :user do
      #     root 'users#index' # creates user_root_path
      #   end
      #
      # If the resource root path is not defined, root_path is used. However,
      # if this default is not enough, you can customize it, for example:
      #
      #   def after_sign_in_path_for(resource)
      #     stored_location_for(resource) ||
      #       if resource.is_a?(User) && resource.can_publish?
      #         publisher_url
      #       else
      #         super
      #       end
      #   end
      #
      def after_sign_in_path_for(resource_or_scope)
        stored_location_for(resource_or_scope) || signed_in_root_path(resource_or_scope)
      end

      # Method used by sessions controller to sign out a user. You can overwrite
      # it in your ApplicationController to provide a custom hook for a custom
      # scope. Notice that differently from +after_sign_in_path_for+ this method
      # receives a symbol with the scope, and not the resource.
      #
      # By default it is the root_path.
      def after_sign_out_path_for(resource_or_scope)
        scope = Kingsman::Mapping.find_scope!(resource_or_scope)
        router_name = Kingsman.mappings[scope].router_name
        context = router_name ? send(router_name) : self
        context.respond_to?(:root_path) ? context.root_path : "/"
      end

      # Sign in a user and tries to redirect first to the stored location and
      # then to the url specified by after_sign_in_path_for. It accepts the same
      # parameters as the sign_in method.
      def sign_in_and_redirect(resource_or_scope, *args)
        options  = args.extract_options!
        scope    = Kingsman::Mapping.find_scope!(resource_or_scope)
        resource = args.last || resource_or_scope
        sign_in(scope, resource, options)
        redirect_to after_sign_in_path_for(resource)
      end

      # Sign out a user and tries to redirect to the url specified by
      # after_sign_out_path_for.
      def sign_out_and_redirect(resource_or_scope)
        scope = Kingsman::Mapping.find_scope!(resource_or_scope)
        redirect_path = after_sign_out_path_for(scope)
        Kingsman.sign_out_all_scopes ? sign_out : sign_out(scope)
        redirect_to redirect_path
      end

      # Overwrite Rails' handle unverified request to sign out all scopes,
      # clear run strategies and remove cached variables.
      def handle_unverified_request
        super # call the default behavior which resets/nullifies/raises
        request.env["kingsman.skip_storage"] = true
        sign_out_all_scopes(false)
      end

      def request_format
        @request_format ||= request.format.try(:ref)
      end

      def is_navigational_format?
        Kingsman.navigational_formats.include?(request_format)
      end

      # Check if flash messages should be emitted. Default is to do it on
      # navigational formats
      def is_flashing_format?
        request.respond_to?(:flash) && is_navigational_format?
      end

      private

      def expire_data_after_sign_out!
        Kingsman.mappings.each { |_,m| instance_variable_set("@current_#{m.name}", nil) }
        super
      end
    end
  end

  class MissingWarden < StandardError
    def initialize
      super "Kingsman could not find the `Warden::Proxy` instance on your request environment.\n" + \
        "Make sure that your application is loading Kingsman and Warden as expected and that " + \
        "the `Warden::Manager` middleware is present in your middleware stack.\n" + \
        "If you are seeing this on one of your tests, ensure that your tests are either " + \
        "executing the Rails middleware stack or that your tests are using the `Kingsman::Test::ControllerHelpers` " + \
        "module to inject the `request.env['warden']` object for you."
    end
  end
end
