# frozen_string_literal: true

module Spree
  module Api
    module V2
      module Storefront
        class RazorpayOrdersController < ::Spree::Api::V2::BaseController
          include Spree::Api::V2::Storefront::OrderConcern # To get spree_current_order

          before_action :require_razorpay_gateway
          # before_action :load_razorpay_transaction, only: [:verify_payment] # Commented out, will load via order

          # POST /api/v2/storefront/razorpay_orders
          def create
            spree_order = spree_current_order
            return render_error_payload('No current order found', :not_found) unless spree_order
            return render_error_payload('Order has no total or is already paid', :unprocessable_entity) if spree_order.total.zero? || spree_order.paid?

            begin
              amount_in_paise = (spree_order.total * 100).to_i
              currency = spree_order.currency

              razorpay_sdk_order = razorpay_gateway.create_razorpay_order(
                amount_in_paise,
                currency,
                spree_order.number,
                { spree_order_number: spree_order.number }
              )

              transaction = SpreeRazorpayCheckout::RazorpayTransaction.create!(
                razorpay_order_id: razorpay_sdk_order.id,
                amount: spree_order.total,
                currency: currency,
                status: 'created',
                spree_order_id: spree_order.id,
                raw_response: razorpay_sdk_order.attributes.to_json
              )

              payload = {
                razorpay_order_id: razorpay_sdk_order.id,
                key_id: razorpay_gateway.preferred_key_id,
                amount: amount_in_paise,
                currency: currency,
                name: current_store.name,
                description: "Order ##{spree_order.number}",
                prefill: {
                  name: spree_order.bill_address&.full_name,
                  email: spree_order.email,
                  contact: spree_order.bill_address&.phone
                },
                notes: {
                  spree_order_number: spree_order.number
                },
                theme: {
                  color: '#3399cc'
                }
              }
              render_serialized_payload { payload }

            rescue ::Razorpay::Error => e # Explicitly namespace Razorpay::Error
              Rails.logger.error "Razorpay Create Order Error: #{e.message} for Spree Order: #{spree_order.number}"
              render_error_payload("Razorpay: #{e.message}", :unprocessable_entity)
            rescue StandardError => e
              Rails.logger.error "General Error creating Razorpay order: #{e.message} for Spree Order: #{spree_order.number}"
              render_error_payload(e.message, :internal_server_error)
            end
          end

          # POST /api/v2/storefront/razorpay_orders/verify_payment
          def verify_payment
            spree_order = spree_current_order
            return render_error_payload('No current order found', :not_found) unless spree_order
            return render_error_payload('Order already paid', :unprocessable_entity) if spree_order.paid?

            payment_params = verify_payment_params
            razorpay_payment_id = payment_params[:razorpay_payment_id]
            razorpay_order_id_from_callback = payment_params[:razorpay_order_id]
            razorpay_signature = payment_params[:razorpay_signature]

            transaction = spree_order.razorpay_transactions.find_by(razorpay_order_id: razorpay_order_id_from_callback)

            if transaction.nil?
              Rails.logger.error "Razorpay Transaction not found for Razorpay Order ID: #{razorpay_order_id_from_callback} and Spree Order: #{spree_order.number}"
              return render_error_payload(Spree.t(:razorpay_payment_error), :not_found)
            end

            begin
              is_signature_valid = razorpay_gateway.verify_payment_signature(
                razorpay_order_id: razorpay_order_id_from_callback,
                razorpay_payment_id: razorpay_payment_id,
                razorpay_signature: razorpay_signature
              )

              unless is_signature_valid
                transaction.update(status: 'failed', raw_response: { error: 'Signature verification failed' }.to_json)
                Rails.logger.error "Razorpay Signature Verification Failed for Spree Order: #{spree_order.number}, Razorpay Payment ID: #{razorpay_payment_id}"
                return render_error_payload(Spree.t(:razorpay_signature_verification_failed), :unprocessable_entity)
              end

              transaction.update(
                razorpay_payment_id: razorpay_payment_id,
                razorpay_signature: razorpay_signature,
                status: 'authorized'
              )

              razorpay_payment_details = ::Razorpay::Payment.fetch(razorpay_payment_id)
              transaction.update(
                payment_method_name: razorpay_payment_details.method,
                raw_response: razorpay_payment_details.attributes.to_json
              )
                payment = spree_order.payments.create!(
                  amount: spree_order.total,
                  payment_method: current_store.payment_methods.find_by(type: 'SpreeRazorpayCheckout::Gateway', active: true),
                  source: transaction,
                  response_code: razorpay_payment_id,
                  state: 'pending'
              )

              if razorpay_payment_details.status == 'authorized' && !razorpay_gateway.auto_capture?
                begin
                  razorpay_gateway.capture_payment(razorpay_payment_id, (spree_order.total * 100).to_i, spree_order.currency)
                  transaction.update(status: 'captured')
                  # payment.capture! # This should be called by Spree after payment is completed or by payment.process!
                rescue ::Razorpay::Error => capture_error
                  Rails.logger.error "Razorpay Capture Error for Payment ID #{razorpay_payment_id}: #{capture_error.message}"
                  return render_error_payload("Payment authorized but capture failed: #{capture_error.message}", :unprocessable_entity)
                end
              elsif razorpay_payment_details.status == 'captured'
                transaction.update(status: 'captured')
              end
              
              if transaction.status == 'captured'
                payment.complete! # Marks payment as complete, Spree handles order update
              else
                # If only authorized, you might want to put the payment into 'processing' or 'auth_only' state
                # For now, we assume capture is the goal or already done.
                # payment.pend! or similar if you want to keep it pending for manual capture in admin.
                Rails.logger.warn "Razorpay payment #{razorpay_payment_id} is authorized but not marked as captured in transaction record for Spree Order #{spree_order.number}."
              end

              render_serialized_payload { { order_number: spree_order.number, payment_status: transaction.status, spree_payment_state: payment.state } }

            rescue ::Razorpay::Error => e
              Rails.logger.error "Razorpay Verify Payment Error: #{e.message} for Spree Order: #{spree_order.number}"
              transaction&.update(status: 'failed', raw_response: { error: e.message }.to_json)
              render_error_payload("Razorpay: #{e.message}", :unprocessable_entity)
            rescue ActiveRecord::RecordInvalid => e
              Rails.logger.error "Validation Error during payment processing: #{e.message} for Spree Order: #{spree_order.number}"
              render_error_payload(e.message, :unprocessable_entity)
            rescue StandardError => e
              Rails.logger.error "General Error verifying Razorpay payment: #{e.message} for Spree Order: #{spree_order.number}"
              transaction&.update(status: 'error', raw_response: { error: e.message }.to_json)
              render_error_payload(e.message, :internal_server_error)
            end
          end

          private

          def resource_serializer
            Spree::Api::V2::Storefront::OrderSerializer
          end
  
            def razorpay_gateway
              @razorpay_gateway ||= current_store.payment_methods.find_by(
                type: 'SpreeRazorpayCheckout::Gateway',
                active: true
              )
            end
  def require_razorpay_gateway
            return if razorpay_gateway.present?
            render_error_payload('Razorpay Checkout gateway not found or not active for this store.', :not_found)
          end

          def verify_payment_params
            params.require(:payment_details).permit(
              :razorpay_payment_id,
              :razorpay_order_id,
              :razorpay_signature
            )
          end
        end
      end
    end
  end
end
