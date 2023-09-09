require 'active_support/core_ext/object/with_options'

# Kingsman.with_options model: true do |k|
#   k.add_module :database_authenticatable
#   # k.add_module :database_authenticatable, controller: :sessions, route: { session: [nil, :new, :destroy] }
# end

Kingsman.with_options model: true do |k|
  # Strategies first
  k.with_options strategy: true do |s|
    routes = [nil, :new, :destroy]
    s.add_module :database_authenticatable, controller: :sessions, route: { session: routes }
    s.add_module :rememberable, no_input: true
  end

  # Other authentications
  k.add_module :omniauthable, controller: :omniauth_callbacks,  route: :omniauth_callback

  # Misc after
  routes = [nil, :new, :edit]
  k.add_module :recoverable,  controller: :passwords,     route: { password: routes }
  k.add_module :registerable, controller: :registrations, route: { registration: (routes << :cancel) }
  k.add_module :validatable

  # The ones which can sign out after
  routes = [nil, :new]
  k.add_module :confirmable,  controller: :confirmations, route: { confirmation: routes }
  k.add_module :lockable,     controller: :unlocks,       route: { unlock: routes }
  k.add_module :timeoutable

  # Stats for last, so we make sure the user is really signed in
  k.add_module :trackable
end
