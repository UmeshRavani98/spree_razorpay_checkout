# lib/spree_razorpay_checkout/gateway.rb
module SpreeRazorpayCheckout
  class Gateway < Spree::PaymentMethod
    preference :key_id, :string
    preference :key_secret, :string

    def payment_source_class
      nil
    end

    def provider_class
      ::Razorpay
    end

    def method_type
      'razorpay_checkout'
    end
  end
end
