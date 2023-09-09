# frozen_string_literal: true

module Kingsman
  module Hooks
    # A small warden proxy so we can remember, forget and
    # sign out users from hooks.
    class Proxy #:nodoc:
      include Kingsman::Controllers::Rememberable
      include Kingsman::Controllers::SignInOut

      attr_reader :warden
      delegate :cookies, :request, to: :warden

      def initialize(warden)
        @warden = warden
      end

      def session
        warden.request.session
      end
    end
  end
end
