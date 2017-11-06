module Api
  module V1
    class DeputiesController < ApiController
      skip_credentials only: [:show, :index]
    end
  end
end
