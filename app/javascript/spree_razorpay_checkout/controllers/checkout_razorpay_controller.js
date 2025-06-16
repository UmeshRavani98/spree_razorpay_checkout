import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    keyId: String,
    orderAmount: Number,
    orderCurrency: String,
    apiCreateOrderPath: String,
    apiVerifyPaymentPath: String,
    returnUrl: String,
  }

  connect() {
    this.initRazorpay();
  }

  initRazorpay() {
    const options = {
      key: this.keyIdValue,
      amount: this.orderAmountValue * 100, // Convert to paise
      currency: this.orderCurrencyValue,
      name: "Your Store",
      description: "Order Payment",
      handler: async function (response) {
        const verifyResponse = await fetch(this.apiVerifyPaymentPathValue, {
          method: "POST",
          headers: { "X-Spree-Order-Token": response.razorpay_order_id },
          body: JSON.stringify({
            payment_id: response.razorpay_payment_id,
            order_id: response.razorpay_order_id,
            signature: response.razorpay_signature
          })
        });

        if (verifyResponse.ok) {
          window.location.href = this.returnUrlValue;
        } else {
          console.error("Payment verification failed");
        }
      }
    };

    const razorpayInstance = new Razorpay(options);
    razorpayInstance.open();
  }
}
