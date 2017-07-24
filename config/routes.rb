Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      jsonapi_resources :stamps do
        jsonapi_relationships
      end
      jsonapi_resources :permissions do
        jsonapi_relationships
      end
      jsonapi_resources :materials do
        jsonapi_relationships
      end
      post 'permissions/check', to: 'permissions#check'
    end
  end
end
