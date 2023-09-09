# frozen_string_literal: true

# loaded from config/initalizers/kingsman.rb
#
#    Kingsman.setup do |config|
#      require 'kingsman/orm/active_record'
#
require 'orm_adapter'
require 'orm_adapter/adapters/active_record'

ActiveSupport.on_load(:active_record) do
  extend Kingsman::Models
end
