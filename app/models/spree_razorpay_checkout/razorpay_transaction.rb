# frozen_string_literal: true

module SpreeRazorpayCheckout
  class RazorpayTransaction < Spree::Base
    # Associations
    belongs_to :payment, class_name: 'Spree::Payment', optional: true
    belongs_to :order, class_name: 'Spree::Order', optional: true # Denormalized for easier querying

    # Validations (add as needed)
    # validates :razorpay_order_id, presence: true
    # validates :razorpay_payment_id, presence: true, uniqueness: { scope: :razorpay_order_id }

    # Store Razorpay specific details
    # Columns to be added via migration:
    # - razorpay_order_id:string
    # - razorpay_payment_id:string
    # - razorpay_signature:string
    # - status:string (e.g., created, authorized, captured, refunded, failed)
    # - payment_method_name:string (e.g., card, netbanking, upi)
    # - amount:decimal
    # - currency:string
    # - raw_response:text (to store the full JSON response from Razorpay for debugging/auditing)
    # - spree_order_id:integer (indexed)
    # - spree_payment_id:integer (indexed)

    def actions
      # For Spree admin UI, if you want to show actions like "Capture" or "Refund"
      # based on the transaction status.
      []
    end
  end
end
