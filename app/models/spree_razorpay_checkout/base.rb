module SpreeRazorpayCheckout
  class Base < ::Spree::Base
    self.abstract_class = true
    self.table_name_prefix = 'spree_razorpay_checkout_'
  end
end
