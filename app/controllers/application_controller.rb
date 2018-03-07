class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action do
    RequestStore.store[:request_id] = request.request_id
  end
end
