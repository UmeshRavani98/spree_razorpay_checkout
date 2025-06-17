module SpreeRazorpayCheckout
  class Order < Base
    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :payment_method, class_name: 'Spree::PaymentMethod'

    validates :razorpay_order_id, presence: true, uniqueness: true
    validates :amount, numericality: { greater_than: 0 }, presence: true

    store_accessor :data, :status, :payment_id

    before_validation :set_amount_from_order, on: :create

    def completed?
      status == 'captured'
    end

    private

    def set_amount_from_order
      self.amount ||= order&.total
    end
  end
end
