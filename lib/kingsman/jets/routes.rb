require "jets/router/dsl"

module Kingsman
  module Router
    def finalize!
      result = super
      Kingsman.configure_warden!
      result
    end
  end
end

module Jets
  module Router
    class RouteSet
      # Ensure Kingsman modules are included only after loading routes, because we
      # need kingsman_for mappings already declared to create filters and helpers.
      prepend Kingsman::Router
    end
  end
end

module Jets::Router
  module Dsl
    def kingsman_for(*resources)
      options = resources.extract_options!

      # options[:as]          ||= @scope[:as]     if @scope[:as].present?
      # options[:module]      ||= @scope[:module] if @scope[:module].present?
      # options[:path_prefix] ||= @scope[:path]   if @scope[:path].present?
      # options[:path_names]    = (@scope[:path_names] || {}).merge(options[:path_names] || {})
      # options[:constraints]   = (@scope[:constraints] || {}).merge(options[:constraints] || {})
      # options[:defaults]      = (@scope[:defaults] || {}).merge(options[:defaults] || {})
      # options[:options]       = @scope[:options] || {}
      # options[:options][:format] = false if options[:format] == false

      resources.map!(&:to_sym)

      resources.each do |resource|
        mapping = Kingsman.add_mapping(resource, options)

        if options[:controllers] && options[:controllers][:omniauth_callbacks]
          unless mapping.omniauthable?
            raise ArgumentError, "Mapping omniauth_callbacks on a resource that is not omniauthable\n" \
              "Please add `kingsman :omniauthable` to the `#{mapping.class_name}` model"
          end
        end

        routes = mapping.used_routes

        kingsman_scope mapping.name do
          with_kingsman_exclusive_scope mapping.fullpath, mapping.name, options do
            routes.each { |mod| send("kingsman_#{mod}", mapping, mapping.controllers) }
          end
        end
      end
    end

    def kingsman_session(mapping, controllers) #:nodoc:
      resource :session, only: [], controller: controllers[:sessions], path: "" do
        get   :new,     path: mapping.path_names[:sign_in],  as: "new"
        post  :create,  path: mapping.path_names[:sign_in]
        match :destroy, path: mapping.path_names[:sign_out], as: "destroy", via: mapping.sign_out_via
      end
    end

    def kingsman_password(mapping, controllers) #:nodoc:
      resource :password, only: [:new, :create, :edit, :update],
        path: mapping.path_names[:password], controller: controllers[:passwords]
    end

    def kingsman_confirmation(mapping, controllers) #:nodoc:
      resource :confirmation, only: [:new, :create, :show],
        path: mapping.path_names[:confirmation], controller: controllers[:confirmations]
    end

    def kingsman_unlock(mapping, controllers) #:nodoc:
      if mapping.to.unlock_strategy_enabled?(:email)
        resource :unlock, only: [:new, :create, :show],
          path: mapping.path_names[:unlock], controller: controllers[:unlocks]
      end
    end

    def kingsman_registration(mapping, controllers) #:nodoc:
      path_names = {
        new: mapping.path_names[:sign_up],
        edit: mapping.path_names[:edit],
        cancel: mapping.path_names[:cancel]
      }

      options = {
        only: [:new, :create, :edit, :update, :destroy],
        path: mapping.path_names[:registration],
        path_names: path_names,
        controller: controllers[:registrations]
      }

      resource :registration, options do
        get :cancel
      end
    end

    def kingsman_omniauth_callback(mapping, controllers) #:nodoc:
      if mapping.fullpath =~ /:[a-zA-Z_]/
        raise <<-ERROR
Kingsman does not support scoping OmniAuth callbacks under a dynamic segment
and you have set #{mapping.fullpath.inspect}. You can work around by passing
`skip: :omniauth_callbacks` to the `kingsman_for` call and extract omniauth
options to another `kingsman_for` call outside the scope. Here is an example:

  kingsman_for :users, only: :omniauth_callbacks, controllers: {omniauth_callbacks: 'users/omniauth_callbacks'}

  scope '/(:locale)', locale: /ru|en/ do
    kingsman_for :users, skip: :omniauth_callbacks
  end
ERROR
      end

      current_scope = @scope.dup

      # Jets routes are all very lazily evaluated.  This is a problem for Kingsman
      # because devise sets the scope[:path] to nil and expects the call to match
      # to use it as it's evaluated. And then it restores it to the previous value.
      # This is a problem for Jets because Jets routes are lazily evaluated and
      # none of this will matter. Unsure how to handle at the moment.

      if @scope.respond_to? :new
        @scope = @scope.new path: nil
      else
        @scope[:path] = nil
      end

      path_prefix = Kingsman.omniauth_path_prefix || "/#{mapping.fullpath}/auth".squeeze("/")
      set_omniauth_path_prefix!(path_prefix)
      path_prefix = "/auth" # HACK

      mapping.to.omniauth_providers.each do |provider|
        match "#{path_prefix}/#{provider}",
          to: "#{controllers[:omniauth_callbacks]}#passthru",
          as: "#{provider}_omniauth_authorize",
          via: OmniAuth.config.allowed_request_methods
          # via: [:get, :post]

        match "#{path_prefix}/#{provider}/callback",
          to: "#{controllers[:omniauth_callbacks]}##{provider}",
          as: "#{provider}_omniauth_callback",
          via: [:get, :post]
      end
    ensure
      @scope = current_scope
    end

    def set_omniauth_path_prefix!(path_prefix) #:nodoc:
      if ::OmniAuth.config.path_prefix && ::OmniAuth.config.path_prefix != path_prefix
        raise "Wrong OmniAuth configuration. If you are getting this exception, it means that either:\n\n" \
          "1) You are manually setting OmniAuth.config.path_prefix and it doesn't match the Devise one\n" \
          "2) You are setting :omniauthable in more than one model\n" \
          "3) You changed your Devise routes/OmniAuth setting and haven't restarted your server"
      else
        ::OmniAuth.config.path_prefix = path_prefix
      end
    end


    def kingsman_scope(scope)
      constraint = lambda do |request|
        request.env["kingsman.mapping"] = Kingsman.mappings[scope]
        true
      end

      constraints(constraint) do
        yield
      end
    end
    alias :as :kingsman_scope

    def with_kingsman_exclusive_scope(new_path, new_as, options) #:nodoc:
      current_scope = @scope.dup

      exclusive = { as: new_as, path: new_path, module: nil }
      exclusive.merge!(options.slice(:constraints, :defaults, :options))

      if @scope.respond_to? :new
        @scope = @scope.new exclusive
      else
        exclusive.each_pair { |key, value| @scope[key] = value }
      end

      yield
    ensure
      @scope = current_scope
    end

  end
end
