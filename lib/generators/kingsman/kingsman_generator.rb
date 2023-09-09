# frozen_string_literal: true

require 'rails/generators/named_base'

module Kingsman
  module Generators
    class KingsmanGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      namespace "kingsman"
      source_root File.expand_path("../templates", __FILE__)

      desc "Generates a model with the given NAME (if one does not exist) with kingsman " \
           "configuration plus a migration file and kingsman routes."

      hook_for :orm, required: true

      class_option :routes, desc: "Generate routes", type: :boolean, default: true

      def add_kingsman_routes
        kingsman_route  = "kingsman_for :#{plural_name}".dup
        kingsman_route << %Q(, class_name: "#{class_name}") if class_name.include?("::")
        kingsman_route << %Q(, skip: :all) unless options.routes?
        route kingsman_route
      end
    end
  end
end
