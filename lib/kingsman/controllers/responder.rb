# frozen_string_literal: true

module Kingsman
  module Controllers
    # Custom Responder to configure default statuses that only apply to Kingsman,
    # and allow to integrate more easily with Hotwire/Turbo.
    class Responder < Jets::Controller::Responder
      if respond_to?(:error_status=) && respond_to?(:redirect_status=)
        self.error_status = :ok
        self.redirect_status = :found
      else
        # TODO: remove this support for older Rails versions, which aren't supported by Turbo
        # and/or responders. It won't allow configuring a custom response, but it allows Kingsman
        # to use these methods and defaults across the implementation more easily.
        def self.error_status
          :ok
        end

        def self.redirect_status
          :found
        end

        def self.error_status=(*)
          warn "[KINGSMAN] Setting the error status on the Kingsman responder has no effect with this " \
            "version of `responders`, please make sure you're using a newer version. Check the changelog for more info."
        end

        def self.redirect_status=(*)
          warn "[KINGSMAN] Setting the redirect status on the Kingsman responder has no effect with this " \
            "version of `responders`, please make sure you're using a newer version. Check the changelog for more info."
        end
      end
    end
  end
end
