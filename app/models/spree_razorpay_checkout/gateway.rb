module SpreeRazorpayCheckout
  class Gateway < ::Spree::Gateway
    #
    # Preferences
    #
    preference :api_key, :string
    preference :api_secret, :string
    preference :test_mode, :boolean, default: true

    #
    # Validations
    #
    validates :preferred_api_key, :preferred_api_secret, presence: true

    def provider_class
      self.class
    end

    def payment_source_class
      Spree::CreditCard # Or define a custom one if needed
    end

    def payment_profiles_supported?
      false
    end

    def method_type
      'spree_razorpay_checkout'
    end

    def default_name
      'Razorpay'
    end

    def payment_icon_name
      'razorpay'
    end

    def purchase(amount_in_cents, source, gateway_options = {})
      order = find_order(gateway_options[:order_id])
      return failure('Order not found') unless order

      amount = amount_in_cents / 100.0

      begin
        razorpay_order = Razorpay::Order.create(
          amount: (amount * 100).to_i,
          currency: order.currency,
          receipt: order.number,
          payment_capture: 1
        )
        success(razorpay_order.id, razorpay_order.to_h)
      rescue => e
        failure(e.message)
      end
    end

    def refund(amount_in_cents, source, razorpay_payment_id, gateway_options = {})
      amount = amount_in_cents / 100.0
      begin
        refund = Razorpay::Refund.create(payment_id: razorpay_payment_id, amount: (amount * 100).to_i)
        success(refund.id, refund.to_h)
      rescue => e
        failure(e.message)
      end
    end

    def void(authorization, source, gateway_options = {})
      failure('Void not supported')
    end

    def cancel(authorization, payment = nil)
      failure('Cancel not supported')
    end

    private

    def find_order(order_id)
      order_number, _ = order_id&.split('-')
      Spree::Order.find_by(number: order_number)
    end

    def success(authorization, response)
      ActiveMerchant::Billing::Response.new(true, 'Transaction successful', response, authorization: authorization)
    end

    def failure(message, response = {})
      ActiveMerchant::Billing::Response.new(false, message, response)
    end
  end
end
