# frozen_string_literal: true

module Kingsman
  module Models
    class MissingAttribute < StandardError
      def initialize(attributes)
        @attributes = attributes
      end

      def message
        "The following attribute(s) is (are) missing on your model: #{@attributes.join(", ")}"
      end
    end

    # Creates configuration values for Kingsman and for the given module.
    #
    #   Kingsman::Models.config(Kingsman::Models::DatabaseAuthenticatable, :stretches)
    #
    # The line above creates:
    #
    #   1) An accessor called Kingsman.stretches, which value is used by default;
    #
    #   2) Some class methods for your model Model.stretches and Model.stretches=
    #      which have higher priority than Kingsman.stretches;
    #
    #   3) And an instance method stretches.
    #
    # To add the class methods you need to have a module ClassMethods defined
    # inside the given class.
    #
    def self.config(mod, *accessors) #:nodoc:
      class << mod; attr_accessor :available_configs; end
      mod.available_configs = accessors

      accessors.each do |accessor|
        mod.class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{accessor}
            if defined?(@#{accessor})
              @#{accessor}
            elsif superclass.respond_to?(:#{accessor})
              superclass.#{accessor}
            else
              Kingsman.#{accessor}
            end
          end

          def #{accessor}=(value)
            @#{accessor} = value
          end
        METHOD
      end
    end

    def self.check_fields!(klass)
      failed_attributes = []
      instance = klass.new

      klass.kingsman_modules.each do |mod|
        constant = const_get(mod.to_s.classify)

        constant.required_fields(klass).each do |field|
          failed_attributes << field unless instance.respond_to?(field)
        end
      end

      if failed_attributes.any?
        fail Kingsman::Models::MissingAttribute.new(failed_attributes)
      end
    end

    # Include the chosen kingsman modules in your model:
    #
    #   kingsman :database_authenticatable, :confirmable, :recoverable
    #
    # You can also give any of the kingsman configuration values in form of a hash,
    # with specific values for this model. Please check your Kingsman initializer
    # for a complete description on those values.
    #
    def kingsman(*modules)
      options = modules.extract_options!.dup

      selected_modules = modules.map(&:to_sym).uniq.sort_by do |s|
        Kingsman::ALL.index(s) || -1  # follow Kingsman::ALL order
      end

      kingsman_modules_hook! do
        include Kingsman::Orm
        include Kingsman::Models::Authenticatable

        selected_modules.each do |m|
          mod = Kingsman::Models.const_get(m.to_s.classify)

          if mod.const_defined?("ClassMethods")
            class_mod = mod.const_get("ClassMethods")
            extend class_mod

            if class_mod.respond_to?(:available_configs)
              available_configs = class_mod.available_configs
              available_configs.each do |config|
                next unless options.key?(config)
                send(:"#{config}=", options.delete(config))
              end
            end
          end

          include mod
        end

        self.kingsman_modules |= selected_modules
        options.each { |key, value| send(:"#{key}=", value) }
      end
    end

    # The hook which is called inside kingsman.
    # So your ORM can include kingsman compatibility stuff.
    def kingsman_modules_hook!
      yield
    end
  end
end

require 'kingsman/models/authenticatable'
