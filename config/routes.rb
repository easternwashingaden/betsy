Rails.application.routes.draw do
  get 'homepages/index'
  get 'categories/index'
  get 'categories/new'
  get 'merchants/index'
  get 'merchants/show'


  root to: "homepages#index"
  resources :products
  # get 'categories/index'
  # get 'categories/new'
  # get 'merchants/index'
  # get 'merchants/show'



  # Merchant
  resources :merchants, only: [:index]
  get "merchants/:id", to: "merchants#account", as: "account"
  # TODO: (Ross) In order to make this nested route works, we have to wait for Lak to merge her Product controller with the "index" action 
  resources :merchants do
    # this nested route will trigger the "index" action in products controller from Lak
    resources :products, only: [:index]
    # this nested route will trigger the "index" action in orders controller from Yaz
    resources :orders, only: [:index]
  end
  get "/auth/github", as: "github_login"
  get "/auth/:provider/callback", to: "merchants#create", as: "omniauth_callback"
  put "/logout", to: "merchants#logout", as: "logout"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html  
end
