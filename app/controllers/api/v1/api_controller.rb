module Api
  module V1
    class ApiController < JSONAPI::ResourceController
      include JWTCredentials

      before_action :check_credentials

      rescue_from CanCan::AccessDenied do |exception|
        respond_to do |format|
          format.json { head :forbidden, content_type: 'text/html' }
          format.api_json { head :forbidden, content_type: 'application/vnd.api+json' }
          format.html { redirect_to root_path, alert: exception.message }
          format.js   { head :forbidden, content_type: 'text/html' }
        end
      end

    private

      def current_user
        session['user']
      end

      def apply_credentials
        RequestStore.store[:x_authorisation] = session['user']
      end

      def context
        { current_user: current_user }
      end

    end
  end
end
