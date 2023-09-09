# frozen_string_literal: true

if defined?(ActionMailer)
  class Kingsman::Mailer < Kingsman.parent_mailer.constantize
    include Kingsman::Mailers::Helpers

    def confirmation_instructions(record, token, opts = {})
      @token = token
      kingsman_mail(record, :confirmation_instructions, opts)
    end

    def reset_password_instructions(record, token, opts = {})
      @token = token
      kingsman_mail(record, :reset_password_instructions, opts)
    end

    def unlock_instructions(record, token, opts = {})
      @token = token
      kingsman_mail(record, :unlock_instructions, opts)
    end

    def email_changed(record, opts = {})
      kingsman_mail(record, :email_changed, opts)
    end

    def password_change(record, opts = {})
      kingsman_mail(record, :password_change, opts)
    end
  end
end
