# frozen_string_literal: true

require 'bcrypt'

module Kingsman
  module Encryptor
    def self.digest(password)
      stretches = 12
      ::BCrypt::Password.create(password, cost: stretches).to_s
    end

    def self.compare(hashed_password, password)
      return false if hashed_password.blank?
      bcrypt   = ::BCrypt::Password.new(hashed_password)
      password = ::BCrypt::Engine.hash_secret(password, bcrypt.salt)
      Kingsman.secure_compare(password, hashed_password)
    end
  end
end
