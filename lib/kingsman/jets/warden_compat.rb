# frozen_string_literal: true

module Warden::Mixins::Common
  def request
    env['jets.controller'].request
  end

  def reset_session!
    request.reset_session
  end

  def cookies
    request.cookie_jar
  end
end
