Rails.application.routes.draw do
  root 'statistics#index'

  get '/login' => 'login#new'
  post '/login' => 'login#create'
  get '/logout' => 'login#destroy'

  namespace :saml do
    get :sso
    post :consume
    get :consume # Not used
    get :metadata
    get :logout
  end

  get '/refugees/suggest'
  get '/refugees/search' => 'refugees#search'
  get '/refugees/drafts' => 'refugees#drafts'
  get '/refugees' => 'refugees#search'

  resources :refugees do
    resources :placements do
      get :move_out
      patch :move_out_update
    end
    resources :relationships
  end

  resources :homes
  resources :moved_out_reasons
  resources :deregistered_reasons
  resources :target_groups
  resources :type_of_housings
  resources :owner_types
  resources :type_of_relationships
  resources :municipalities
  resources :countries
  resources :languages
  resources :genders
  resources :users, only: :index
  resources :statistics, only: :index

  get  'reports' => 'reports#index'
  post 'reports/generate'
  get  'reports/status/:job_id/:file_id' => 'reports#status', as: 'reports_status'
  get  'reports/download/:id' => 'reports#download', as: 'reports_download'
  get  'reports/download_pre_generated/:id' => 'reports#download_pre_generated', as: 'reports_download_pre_generated'

  match '*path', via: :all, to: 'errors#not_found'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
