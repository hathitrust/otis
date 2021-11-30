# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users

  scope constraints: {id: /.+/} do
    resources :ht_users
  end

  scope format: false, constraints: {id: /.+/} do
    resources :approval_requests
  end

  root "ht_users#index"

  scope format: false, constraints: {id: /.+/} do
    resources :ht_institutions
  end

  scope format: false, constraints: {id: /.+/} do
    resources :contacts
  end

  scope format: false, constraints: {id: /.+/} do
    resources :contact_types
  end

  scope constraints: {id: /.+/} do
    resources :otis_logs
  end

  scope format: false, constraints: {id: /.+/} do
    resources :registrations
  end

  get "/login", to: "session#new", as: "login"
  post "/login", to: "session#create", as: "login_as"
  unless Rails.env.production?
    match "/logout", to: "session#destroy", as: "logout", via: [:get, :post]
  end

  get "/approve/:token", to: "approval#new", as: :approve

  unless Rails.env.production?
    get "Shibboleth.sso/Login", controller: :fake_shib, as: :fake_shib, action: :new
  end
end
