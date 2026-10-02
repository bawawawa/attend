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
#
# Ordering: initializers load in filename order and devise.rb sorts before this
# file, so Devise.omniauth_configs[:hack_club] already exists by the time the line
# below runs. Assigning the attributes is sufficient because omniauth-oauth2
# builds its ::OAuth2::Client lazily on first use, which is per-request and long
# after this file has loaded — nothing has memoized a client yet.

provider = defined?(Devise) ? Devise.omniauth_configs[:hack_club] : nil
return if provider.nil?

client_id = ENV["HACK_CLUB_CLIENT_ID"].presence
client_secret = ENV["HACK_CLUB_CLIENT_SECRET"].presence

if client_id && client_secret
  provider.client_id = client_id
  provider.client_secret = client_secret
elsif client_id || client_secret
  # Registering only one half produces a redirect that fails at the token
  # exchange instead of at the authorize step, which is a much worse error to
  # diagnose. Treat a partial pair as absent and fall back to credentials.
  Rails.logger.warn(
    "[hack_club] HACK_CLUB_CLIENT_ID and HACK_CLUB_CLIENT_SECRET must both be set; " \
    "ignoring the partial pair and falling back to credentials."
  )
end