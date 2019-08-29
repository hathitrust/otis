# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users
  scope format:false, constraints: { id: /.+/ } do
    resources :ht_users
  end
  root 'ht_users#index'

  get "/login", to: "session#new", as: "login"
  post "/login", to: "session#create", as: "login_as"
  match "/logout", to: "session#destroy", as: "logout", via: [:get, :post]
end
