Rails.application.config.after_initialize do
  # Register your custom gateway
  Rails.application.config.spree.payment_methods << SpreeRazorpayCheckout::Gateway
end
