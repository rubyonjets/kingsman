require "kingsman/jets/routes"
require "kingsman/jets/warden_compat"

module Kingsman
  class Engine < ::Jets::Engine
    config.kingsman = ActiveSupport::OrderedOptions.new

    config.app_middleware.use Warden::Manager do |manager|
      Kingsman.warden_config = manager
    end

    initializer "kingsman.url_helpers" do
      Kingsman.include_helpers(Kingsman::Controllers)
    end

    initializer "kingsman.omniauth", after: :load_config_initializers, before: :build_middleware_stack do |app|
      Kingsman.omniauth_configs.each do |provider, config|
        app.middleware.use config.strategy_class, *config.args do |strategy|
          config.strategy = strategy
        end
      end

      if Kingsman.omniauth_configs.any?
        Kingsman.include_helpers(Kingsman::OmniAuth)
      end
    end

    initializer "kingsman.secret_key" do |app|
      Kingsman.secret_key ||= Kingsman::SecretKeyFinder.new(app).find

      Kingsman.token_generator ||=
        if secret_key = Kingsman.secret_key
          Kingsman::TokenGenerator.new(
            ActiveSupport::CachingKeyGenerator.new(ActiveSupport::KeyGenerator.new(secret_key))
          )
        end
    end
  end
end
