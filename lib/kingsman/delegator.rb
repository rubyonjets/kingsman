# frozen_string_literal: true

module Kingsman
  # Checks the scope in the given environment and returns the associated failure app.
  class Delegator
    def call(env)
      failure_app(env).call(env)
    end

    def failure_app(env)
      app = env["warden.options"] &&
        (scope = env["warden.options"][:scope]) &&
        Kingsman.mappings[scope.to_sym].failure_app

      app || Kingsman::FailureApp
    end
  end
end
