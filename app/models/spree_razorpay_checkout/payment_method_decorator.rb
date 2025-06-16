module SpreeRazorpayCheckout
  module PaymentMethodDecorator
    RAZORPAY_CHECKOUT_TYPE = 'SpreeRazorpayCheckout::Gateway'.freeze

    def self.prepended(base)
      base.scope :razorpay_checkout, -> { where(type: RAZORPAY_CHECKOUT_TYPE) }
    end

    def razorpay_checkout?
      type == RAZORPAY_CHECKOUT_TYPE
    end
  end
end

Spree::PaymentMethod.prepend(SpreeRazorpayCheckout::PaymentMethodDecorator)
