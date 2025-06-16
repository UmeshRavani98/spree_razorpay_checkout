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

    this.createOrderUrl = Spree.routes.api_v1_storefront_razorpay_orders; // Updated to /v1/
    this.verifyPaymentUrl = '/api/v1/storefront/razorpay_orders/verify_payment'; // Updated to /v1/

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
    fetch(this.createOrderUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCsrfToken()
      },
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
        const razorpayOptions = {
          key: data.key_id,
          amount: data.amount,
          currency: data.currency,
          name: data.name,
          description: data.description,
          order_id: data.razorpay_order_id,
          handler: (response) => {
            this.verifyPaymentOnServer(response);
          },
          prefill: data.prefill,
          notes: data.notes,
          theme: data.theme,
          modal: {
            ondismiss: () => {
              console.log('Razorpay checkout modal dismissed.');
              this.displayError(Spree.translations.payment_cancelled || 'Payment cancelled.');
              this.enableButton();
            }
          }
        };

        const rzp = new Razorpay(razorpayOptions);
        rzp.on('payment.failed', (response) => {
          console.error('Razorpay payment failed:', response.error);
          this.displayError(
            `Payment Failed: ${response.error.description} (Reason: ${response.error.reason}, Step: ${response.error.step})`
          );
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
        console.log('Payment verification successful:', data);
        window.location.reload();
      })
      .catch(error => {
        console.error('Error verifying Razorpay payment:', error);
        this.displayError(error.message || (Spree.translations.razorpay_signature_verification_failed || 'Payment verification failed.'));
        this.enableButton();
      });
  }
}

document.addEventListener('spree:load', function () {
  const razorpayPaymentForms = document.querySelectorAll('.razorpay-payment-form');
  razorpayPaymentForms.forEach(form => {
    const paymentMethodId = form.dataset.paymentMethodId;
    if (paymentMethodId) {
      new SpreeRazorpayHandler(paymentMethodId);
    }
  });
});
