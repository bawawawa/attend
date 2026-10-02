# Hack Club Auth credentials from the environment.
#
# config/initializers/devise.rb registers the :hack_club OmniAuth provider with
# `Rails.application.credentials.dig(:hack_club, :client_id)` and
# `:client_secret`. A deployment without RAILS_MASTER_KEY therefore registers the
# provider with nil credentials, and the sign-in redirect goes to
# `https://auth.hackclub.com/oauth/authorize?client_id&redirect_uri=...` — an
# empty client_id that Hack Club rejects. Prefer the environment when it supplies
# both values, so a deployment can run against its own OAuth client without
# credentials. This mirrors the ENV-first-then-credentials shape already used for
# DATABASE_URL in config/database.yml and POSTMARK_API_TOKEN in
# config/environments/production.rb.
#
# The provider is overridden here rather than edited in devise.rb so that the
# credentials/devise.rb path stays exactly as it is for every deployment that
# does have a master key.

config = defined?(Devise) ? Devise.omniauth_configs[:hack_club] : nil
return if config.nil? || !config.respond_to?(:args)

client_id = ENV["HACK_CLUB_CLIENT_ID"].presence
client_secret = ENV["HACK_CLUB_CLIENT_SECRET"].presence

if client_id && client_secret
  # Devise holds the provider as Devise::OmniAuth::Config, whose `args` are the
  # positional arguments devise.rb passed to `config.omniauth` — here
  # [client_id, client_secret, { scope: ... }] — and builds the middleware as
  #
  #   app.middleware.use config.strategy_class, *config.args
  #
  # in its `devise.omniauth` initializer, declared `after: :load_config_initializers`
  # (see devise/rails.rb). Rewriting args[0] and args[1] here therefore lands
  # before the middleware is constructed.
  #
  # Assigning config.strategy would not survive: devise.omniauth sets
  # `config.strategy = strategy` from the middleware block, so anything set
  # before the first request is overwritten by the real strategy instance.
  #
  # `args` is attr_reader only, but the array is mutated in place rather than
  # replaced. `config.options` is a reference to the trailing Hash and is
  # untouched by this, so the scope stays as devise.rb set it.
  config.args[0] = client_id
  config.args[1] = client_secret
elsif client_id || client_secret
  # Registering only one half produces a redirect that fails at the token
  # exchange instead of at the authorize step, which is a much worse error to
  # diagnose. Treat a partial pair as absent and fall back to credentials.
  Rails.logger.warn(
    "[hack_club] HACK_CLUB_CLIENT_ID and HACK_CLUB_CLIENT_SECRET must both be set; " \
    "ignoring the partial pair and falling back to credentials."
  )
end