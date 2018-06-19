# frozen_string_literal: true

Rails.application.routes.draw do
  resources :tasks, except: %i[destroy] do
    delete :index, on: :collection, action: :delete
  end
end
