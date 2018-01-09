class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action do
    # This should not be enabled on any public-facing environment
    Rack::MiniProfiler.authorize_request unless Rails.env.production?
  end
end
