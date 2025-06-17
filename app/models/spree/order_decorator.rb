# frozen_string_literal: true

module Spree
  module OrderDecorator
    def self.prepended(base)
      base.has_many :razorpay_transactions, class_name: 'SpreeRazorpayCheckout::RazorpayTransaction', foreign_key: 'spree_order_id', dependent: :destroy
    end
  end
end

# Ensure the decorator is applied to Spree::Order
if Spree::Order.included_modules.exclude?(Spree::OrderDecorator)
  Spree::Order.prepend Spree::OrderDecorator
end
