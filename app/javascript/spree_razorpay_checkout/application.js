import "@hotwired/turbo-rails";
import { Application } from "@hotwired/stimulus";

let application;

if (typeof window.Stimulus === "undefined") {
  application = Application.start();
  application.debug = false;
  window.Stimulus = application;
} else {
  application = window.Stimulus;
}

import CheckoutRazorpayController from "spree_razorpay_checkout/controllers/checkout_razorpay_controller";

application.register("checkout-razorpay", CheckoutRazorpayController);
