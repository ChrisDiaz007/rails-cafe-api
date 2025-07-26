Rails.application.routes.draw do
  root to: 'pages#home'
  #get 'pages/home'
  # as a user, i can see all my cafes.
  #  '/api/v1/cafes'
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :cafes, only: [ :index, :create ]
    end
  end
  # as a user, i can search through all of my cafes.
  # as a user, i can add a cafe.
end
