# frozen_string_literal: true

module SpreeRazorpayCheckout
  class Configuration < Spree::Preferences::Configuration
    # Example preference:
    # preference :webhook_secret, :string

    # You can add any specific configuration options your gateway might need here.
    # For now, Key ID and Key Secret will be handled as standard Spree::Gateway preferences.
  end
end
