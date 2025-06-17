# frozen_string_literal: true

class CreateSpreeRazorpayCheckoutTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :spree_razorpay_checkout_transactions do |t|
      t.string :razorpay_order_id
      t.string :razorpay_payment_id
      t.string :razorpay_signature
      t.string :status
      t.string :payment_method_name
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency
      t.text :raw_response

      t.references :spree_order, foreign_key: { to_table: :spree_orders }, index: true
      t.references :spree_payment, foreign_key: { to_table: :spree_payments }, index: true

      t.timestamps
    end

    # Shortened index names
    add_index :spree_razorpay_checkout_transactions, :razorpay_order_id, name: 'idx_razorpay_oid'
    add_index :spree_razorpay_checkout_transactions, :razorpay_payment_id, name: 'idx_razorpay_pid'

    # Optional unique index with shortened name
    # add_index :spree_razorpay_checkout_transactions, [:razorpay_order_id, :razorpay_payment_id], unique: true, name: 'idx_razorpay_order_payment_uniq'
  end
end

