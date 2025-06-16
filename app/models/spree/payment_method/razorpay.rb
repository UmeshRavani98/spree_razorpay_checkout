# frozen_string_literal: true

module Spree
  class PaymentMethod::Razorpay < PaymentMethod
    preference :key_id, :string, default: ENV.fetch('RAZORPAY_KEY_ID', '')
    preference :key_secret, :string, default: ENV.fetch('RAZORPAY_KEY_SECRET', '')
    preference :webhook_secret, :string, default: ENV.fetch('RAZORPAY_WEBHOOK_SECRET', '')
    preference :theme_color, :string, default: '#3399cc'
    preference :notes, :string, default: 'Integrated via Spree'          

    def provider_class
      ::Razorpay
    end

    def payment_source_class
      Spree::CreditCard
    end

    def auto_capture?
      true
    end

    def purchase(amount_in_cents, source, gateway_options)
      # Implement Razorpay API interaction here
    end
  end
end
