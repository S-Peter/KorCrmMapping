Rails.application.routes.draw do

  resources :kinds, only: [:index, :edit, :update, :destroy]
  resources :relations, only: [:index, :edit, :destroy]
  
  get 'relations/edit', to: 'relations#edit'
  get 'relations/editDomain', to: 'relations#editDomain'
  get 'relations/editRange', to: 'relations#editRange'
  post 'relations/updateDomainOrRange', to: 'relations#updateDomainOrRange'
  
  get 'relations/editPathProperty', to: 'relations#editPathProperty'
  post 'relations/updatePathProperty', to: 'relations#updatePathProperty'
  
  get 'relations/editPathClass', to: 'relations#editPathClass'
  post 'relations/updatePathClass', to: 'relations#updatePathClass'
  
  post 'relations/updateCompletePath', to: 'relations#updateCompletePath'
  post 'relations/updatePath', to: 'relations#updatePath'
  
  get 'relations/destroy', to: 'relations#destroy' # delete not working! why?

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'kinds#index'

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
