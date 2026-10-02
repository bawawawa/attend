require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Attend
  class Application < Rails::Application
    # Initialize configuration defaults from previously generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks omniauth])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Discards sends to Postmark-suppressed addresses instead of erroring.
    config.action_mailer.delivery_job = "MailDeliveryJob"

    # Active Record encryption keys, taken from the environment when it supplies
    # them. This keeps a deployment runnable without RAILS_MASTER_KEY: with no
    # master key Rails uses EmptyCredentials, and the railtie's
    # `active_record_encryption.configuration` initializer then finds nothing,
    # leaving every `encrypts` attribute to raise
    # ActiveRecord::Encryption::Errors::Configuration when it is touched.
    #
    # Credentials stay the fallback, so a deployment that does set
    # RAILS_MASTER_KEY behaves exactly as before. Where both are present the
    # environment wins, because the railtie splats this config over whatever it
    # read from credentials:
    #
    #   ActiveRecord::Encryption.configure(
    #     primary_key: app.credentials.dig(:active_record_encryption, :primary_key),
    #     ...,
    #     **app.config.active_record.encryption
    #   )
    #
    # This has to live here rather than in config/initializers: that railtie
    # initializer captures the key material when it runs, whereas
    # support_unencrypted_data is read lazily on each query, which is why the
    # existing config/initializers/active_record_encryption.rb can set it that
    # late. application.rb is evaluated before any initializer runs, so a key
    # set here is always in place in time.
    #
    # Generate a set with `bin/rails db:encryption:init`. Changing any of these
    # after data has been encrypted makes the existing ciphertext unreadable —
    # deterministic keys additionally break equality lookups on encrypted
    # columns such as accommodation.gender_identity.
    if ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].present?
      config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    end

    if ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].present?
      config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    end

    if ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].present?
      config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
    end
  end
end