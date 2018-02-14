require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AkerStamps
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.generators do |g|
      # This ensures that all migrations set id: :uuid in create_table
      g.orm :active_record, primary_key_type: :uuid
    end

    config.accessible_id_type = :uuid

    config.autoload_paths << Rails.root.join('lib')

  end
end
