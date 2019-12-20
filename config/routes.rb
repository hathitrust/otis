# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users
  resources :ht_institutions, path: :institutions, as: :institutions, only: [:index]

  scope format:false, constraints: { id: /.+/ } do
    resources :ht_users
  end
  root 'ht_users#index'

  #get '/institutions', to: 'ht_institutions#index'

  get "/login", to: "session#new", as: "login"
  post "/login", to: "session#create", as: "login_as"
  unless Rails.env.production?
    match "/logout", to: "session#destroy", as: "logout", via: [:get, :post]
  end

  unless Rails.env.production?
    get 'Shibboleth.sso/Login', controller: :fake_shib, as: :fake_shib, action: :new
  end
end
