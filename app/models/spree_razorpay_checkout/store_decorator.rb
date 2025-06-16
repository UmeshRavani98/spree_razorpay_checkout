module SpreeRazorpayCheckout
  module StoreDecorator
    def razorpay_checkout_gateway
      @razorpay_checkout_gateway ||= payment_methods.razorpay_checkout.active.last
    end
  end
end

Spree::Store.prepend(SpreeRazorpayCheckout::StoreDecorator)
