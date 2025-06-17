module SpreeRazorpayCheckout
  module OrderDecorator
    def self.prepended(base)
      base.has_many :razorpay_checkout_orders, class_name: 'SpreeRazorpayCheckout::Order', dependent: :destroy, foreign_key: :order_id
    end
  end
end

Spree::Order.prepend(SpreeRazorpayCheckout::OrderDecorator)
