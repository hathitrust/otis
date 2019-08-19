# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users
  resources :ht_users, defaults: { format: 'html' }
  root 'ht_users#index'

  get "/login", to: "session#new", as: "login"
  post "/login", to: "session#create", as: "login_as"
  match "/logout", to: "session#destroy", as: "logout", via: [:get, :post]
end
