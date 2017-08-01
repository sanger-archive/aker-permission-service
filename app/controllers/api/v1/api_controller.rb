module Api
  module V1
    class ApiController < JSONAPI::ResourceController
      include JWTCredentials

      rescue_from CanCan::AccessDenied do |exception|
        head :forbidden, content_type: 'application/vnd.api+json'
      end

    private

      def context
        { current_user: current_user }
      end

    end
  end
end
