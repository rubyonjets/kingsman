# frozen_string_literal: true

module Kingsman
  module Mailers
    module Helpers
      extend ActiveSupport::Concern

      included do
        include Kingsman::Controllers::ScopedViews
      end

      protected

      attr_reader :scope_name, :resource

      # Configure default email options
      def kingsman_mail(record, action, opts = {}, &block)
        initialize_from_record(record)
        mail headers_for(action, opts), &block
      end

      def initialize_from_record(record)
        @scope_name = Kingsman::Mapping.find_scope!(record)
        @resource   = instance_variable_set("@#{kingsman_mapping.name}", record)
      end

      def kingsman_mapping
        @kingsman_mapping ||= Kingsman.mappings[scope_name]
      end

      def headers_for(action, opts)
        headers = {
          subject: subject_for(action),
          to: resource.email,
          from: mailer_sender(kingsman_mapping),
          reply_to: mailer_reply_to(kingsman_mapping),
          template_path: template_paths,
          template_name: action
        }.merge(opts)

        @email = headers[:to]
        headers
      end

      def mailer_reply_to(mapping)
        mailer_sender(mapping, :reply_to)
      end

      def mailer_from(mapping)
        mailer_sender(mapping, :from)
      end

      def mailer_sender(mapping, sender = :from)
        default_sender = default_params[sender]
        if default_sender.present?
          default_sender.respond_to?(:to_proc) ? instance_eval(&default_sender) : default_sender
        elsif Kingsman.mailer_sender.is_a?(Proc)
          Kingsman.mailer_sender.call(mapping.name)
        else
          Kingsman.mailer_sender
        end
      end

      def template_paths
        template_path = _prefixes.dup
        template_path.unshift "#{@kingsman_mapping.scoped_path}/mailer" if self.class.scoped_views?
        template_path
      end

      # Set up a subject doing an I18n lookup. At first, it attempts to set a subject
      # based on the current mapping:
      #
      #   en:
      #     kingsman:
      #       mailer:
      #         confirmation_instructions:
      #           user_subject: '...'
      #
      # If one does not exist, it fallbacks to ActionMailer default:
      #
      #   en:
      #     kingsman:
      #       mailer:
      #         confirmation_instructions:
      #           subject: '...'
      #
      def subject_for(key)
        I18n.t(:"#{kingsman_mapping.name}_subject", scope: [:kingsman, :mailer, key],
          default: [:subject, key.to_s.humanize])
      end
    end
  end
end
