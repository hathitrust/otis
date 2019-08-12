# frozen_string_literal: true

Rails.application.routes.draw do
  resources :ht_users, defaults: { format: 'html' }
  root 'ht_users#index'
end
