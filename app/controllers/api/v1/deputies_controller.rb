module Api
  module V1
    class DeputiesController < ApiController
      skip_credentials only: [:show, :index, :list_principals]

      def list_principals
        user_acts_as = Deputy.where(deputy: params[:email]).pluck(:user_email).to_json
        render json: user_acts_as
      end
    end
  end
end
