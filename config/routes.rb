Rails.application.routes.draw do
  apipie
  # api routes
  namespace :api do
    namespace :v1 do
      match 'push_data' => 'push_data#index', via: [:get, :post]
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
