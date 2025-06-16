module Spree
  module Razorpay
    class PaymentsController < Spree::StoreController
      protect_from_forgery with: :null_session # if calling from JS

      def create_order
        order_number = params[:order_number]
        amount = params[:amount]

        # Fetch the order (example)
        order = Spree::Order.find_by!(number: order_number)

        # Example Razorpay call
        razorpay_order = Razorpay::Order.create(
          amount: amount,
          currency: 'INR',
          receipt: order_number,
          payment_capture: 1
        )

        render json: {
          razorpay_order_id: razorpay_order.id,
          amount: amount
        }
      rescue => e
        render json: { error: e.message }, status: 500
      end
    end
  end
end
