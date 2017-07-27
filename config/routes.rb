Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      jsonapi_resources :stamps do
        jsonapi_relationships only: [ :show, :get_related_resources ]
        post 'set_permissions', to: :set_permissions
      end
      jsonapi_resources :permissions, only: [ :create, :show, :index, :destroy ] do
        jsonapi_relationships only: [ :show, :get_related_resource ]
      end
      jsonapi_resources :materials, only: [ :create, :show, :index, :destroy ] do
        jsonapi_relationships only: [ :show, :get_related_resource ]
      end
      post 'permissions/check', to: 'permissions#check'
    end
  end
end
