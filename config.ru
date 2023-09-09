# This file is used by Rack-based servers to start the application.

require "jets"
Jets.boot
require_relative "lib/kingsman/engine"
run Kingsman::Engine.instance
