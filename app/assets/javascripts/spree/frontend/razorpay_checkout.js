// Ensure this script is loaded after jQuery (if used) and Spree's core JS.
// It's also good practice to wrap this in a Spree.ready() or similar DOMContentLoaded listener.

// Make sure to include Razorpay's checkout.js script in your application.
// You can do this via a script tag in your layout, or by importing it if using a JS bundler.
// <script src="https://checkout.razorpay.com/v1/checkout.js"></script>

class SpreeRazorpayHandler {
  constructor(paymentMethodId) {
    this.paymentMethodId = paymentMethodId;
    this.paymentForm = document.getElementById(`razorpay-payment-form-${paymentMethodId}`);
    if (!this.paymentForm) {
      console.error(`Razorpay: Payment form for method ID ${paymentMethodId} not found.`);
      return;
    }

    this.paymentButton = document.getElementById(`razorpay-payment-button-${paymentMethodId}`);
    this.errorContainer = document.getElementById(`razorpay-error-${paymentMethodId}`);

    // API endpoints - these should ideally be configurable or discoverable
    // For now, using relative paths assuming standard Spree API structure.
    // Ensure your Spree::Store.default.url is configured correctly for absolute URLs if needed by helpers.
    this.createOrderUrl = Spree.routes.api_v2_storefront_razorpay_orders; // Check Spree.routes for exact path
    this.verifyPaymentUrl = '/api/v2/storefront/razorpay_orders/verify_payment'; // Or use Spree.routes if available for custom named route

    this.bindEvents();
  }

  bindEvents() {
    if (this.paymentButton) {
      this.paymentButton.addEventListener('click', (event) => {
        event.preventDefault();
        this.disableButton();
        this.clearErrors();
        this.initiatePayment();
      });
    }
  }

  displayError(message) {
    if (this.errorContainer) {
      this.errorContainer.textContent = message;
      this.errorContainer.style.display = 'block';
    }
    this.enableButton();
  }

  clearErrors() {
    if (this.errorContainer) {
      this.errorContainer.textContent = '';
      this.errorContainer.style.display = 'none';
    }
  }

  disableButton() {
    if (this.paymentButton) {
      this.paymentButton.disabled = true;
      this.paymentButton.innerHTML = Spree.translations.processing || 'Processing...'; // Add Spree.translations.processing
    }
  }

  enableButton() {
    if (this.paymentButton) {
      this.paymentButton.disabled = false;
      this.paymentButton.innerHTML = Spree.translations.pay_with_razorpay || 'Pay with Razorpay'; // Use translation
    }
  }

  getCsrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
  }

  initiatePayment() {
    // 1. Call backend to create Razorpay Order
    fetch(this.createOrderUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCsrfToken()
        // Add any other headers Spree API v2 might require (e.g., Order token)
        // Spree.apiV2Authentication() or similar might be needed if your API is protected
      },
      // body: JSON.stringify({ payment_method_id: this.paymentMethodId }) // Send PM ID if needed by controller
    })
      .then(response => {
        if (!response.ok) {
          return response.json().then(errorData => {
            throw new Error(errorData.error || errorData.errors?.join(', ') || `HTTP error! Status: ${response.status}`);
          });
        }
        return response.json();
      })
      .then(data => {
        // Data should contain: razorpay_order_id, key_id, amount, currency, name, description, prefill, notes, theme
        const razorpayOptions = {
          key: data.key_id,
          amount: data.amount, // Amount in paise
          currency: data.currency,
          name: data.name,
          description: data.description,
          order_id: data.razorpay_order_id,
          handler: (response) => {
            // 3. Send payment details to backend for verification
            this.verifyPaymentOnServer(response);
          },
          prefill: data.prefill,
          notes: data.notes,
          theme: data.theme,
          modal: {
            ondismiss: () => {
              // Handle modal dismissal (e.g., user closes Razorpay popup)
              console.log('Razorpay checkout modal dismissed.');
              this.displayError(Spree.translations.payment_cancelled || 'Payment cancelled.'); // Add translation
              this.enableButton();
            }
          }
        };

        // 2. Open Razorpay Checkout
        const rzp = new Razorpay(razorpayOptions);
        rzp.on('payment.failed', (response) => {
          // Handle payment failure on Razorpay's side
          console.error('Razorpay payment failed:', response.error);
          this.displayError(
            `Payment Failed: ${response.error.description} (Reason: ${response.error.reason}, Step: ${response.error.step})`
          );
          // Optionally, send failure details to your server for logging
          this.enableButton();
        });
        rzp.open();
      })
      .catch(error => {
        console.error('Error initiating Razorpay payment:', error);
        this.displayError(error.message || (Spree.translations.razorpay_payment_error || 'Could not initiate Razorpay payment.'));
        this.enableButton();
      });
  }

  verifyPaymentOnServer(paymentDetails) {
    fetch(this.verifyPaymentUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCsrfToken()
        // Add Spree API v2 authentication headers if needed
      },
      body: JSON.stringify({
        payment_details: {
          razorpay_payment_id: paymentDetails.razorpay_payment_id,
          razorpay_order_id: paymentDetails.razorpay_order_id,
          razorpay_signature: paymentDetails.razorpay_signature
        }
      })
    })
      .then(response => {
        if (!response.ok) {
          return response.json().then(errorData => {
            throw new Error(errorData.error || errorData.errors?.join(', ') || `HTTP error! Status: ${response.status}`);
          });
        }
        return response.json();
      })
      .then(data => {
        // Backend should respond with success and ideally the redirect URL (e.g., order confirmation page)
        // or a status that indicates success.
        console.log('Payment verification successful:', data);
        // Redirect to Spree's order confirmation page (or next step in checkout if applicable)
        // Spree's default checkout flow should handle redirection upon successful payment processing.
        // If the payment state updates correctly, Spree's checkout flow might auto-advance.
        // If not, you might need to manually redirect:
        // window.location.href = Spree.routes.order_confirmation_url || `/checkout/confirm`; // Adjust as needed
        // For now, assume Spree's checkout flow handles the redirect after payment state update.
        // A page reload might be necessary if Spree's checkout doesn't auto-update.
        window.location.reload(); // Simplest way to reflect order update, or use Spree's JS framework for updates.
      })
      .catch(error => {
        console.error('Error verifying Razorpay payment:', error);
        this.displayError(error.message || (Spree.translations.razorpay_signature_verification_failed || 'Payment verification failed.'));
        this.enableButton(); // Re-enable button on verification failure
      });
  }
}

// Initialize handlers for all Razorpay payment methods on the page
// This should run after the DOM is fully loaded.
document.addEventListener('spree:load', function () { // Spree's Turbo event or use DOMContentLoaded
  const razorpayPaymentForms = document.querySelectorAll('.razorpay-payment-form');
  razorpayPaymentForms.forEach(form => {
    const paymentMethodId = form.dataset.paymentMethodId;
    if (paymentMethodId) {
      new SpreeRazorpayHandler(paymentMethodId);
    }
  });
});

// Add new translations to en.yml:
// Spree.translations.processing = "Processing..."
// Spree.translations.payment_cancelled = "Payment cancelled."
