# frozen_string_literal: true
  Spree::Core::Engine.routes.draw do
    namespace :api do
      namespace :v2 do
        namespace :storefront do
          post 'razorpay/create_order', to: 'razorpay_orders#create'
          post :verify_payment, to: 'razorpay_orders#verify_payment'
  end
    end
end
end
