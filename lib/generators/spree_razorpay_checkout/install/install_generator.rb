# frozen_string_literal: true

module SpreeRazorpayCheckout
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :auto_run_migrations, type: :boolean, default: false
      class_option :skip_asset_guidance, type: :boolean, default: false

      def add_migrations
        puts "\n⚙️ Installing migrations for Spree Razorpay Checkout..."
        run 'bundle exec rake railties:install:migrations FROM=spree_razorpay_checkout'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask("\nWould you like to run the migrations now? [Y/n]"))
        
        if run_migrations
          puts "\n🚀 Running migrations..."
          run 'bundle exec rake db:migrate'
          create_payment_method
        else
          puts "\n❗ Skipping migrations. Don't forget to run `bundle exec rake db:migrate` manually!"
        end
      end

      def create_payment_method
  puts "\n🔍 Checking for existing Razorpay payment method..."
  if Spree::PaymentMethod.exists?(type: 'Spree::PaymentMethod::Razorpay')
    puts "⚠️ Razorpay payment method already exists. Skipping creation."
    return
  end

  puts "\n➕ Adding Razorpay as a Spree payment method..."
  Spree::PaymentMethod.create!(
    type: 'Spree::PaymentMethod::Razorpay',
    name: 'Razorpay Checkout',
    description: 'Process payments via Razorpay',
    active: true,
    preferences: {
      key_id: ENV.fetch('RAZORPAY_KEY_ID', ''),
      key_secret: ENV.fetch('RAZORPAY_KEY_SECRET', ''),
      webhook_secret: ENV.fetch('RAZORPAY_WEBHOOK_SECRET', ''),
      theme_color: '#3399cc',
      notes: 'Integrated via Spree'
    }
  )
  puts "✅ Razorpay successfully added with initialized preferences!"
end


      def asset_guidance
        return if options[:skip_asset_guidance]

        puts "\n--------------------------------------------------------------------------------"
        puts "📌 Spree Razorpay Checkout Installation Notes:"
        puts "--------------------------------------------------------------------------------"
        puts "\n1️⃣ Ensure Razorpay's Checkout.js is included in your application:"
        puts "   Add the following script tag to your main layout file (e.g., `app/views/layouts/spree/application.html.erb`), ideally in `<head>` or before your closing `</body>` tag:"
        puts '   <script src="https://checkout.razorpay.com/v1/checkout.js"></script>'
        puts "\n2️⃣ Ensure your custom JavaScript (`spree/frontend/razorpay_checkout.js`) is loaded:"
        puts "   - **Sprockets (older Spree):** Add `//= require spree/frontend/razorpay_checkout` to `vendor/assets/javascripts/spree/frontend/all.js`."
        puts "   - **Importmaps (newer Spree):** Pin the file if it’s not automatically picked up, or manually import it in `app/javascript/application.js`."
        puts "   - **JS bundlers (Webpacker, Esbuild):** Ensure it is imported into your main JavaScript entry point."
        puts "   Refer to Spree's frontend customization documentation for specific setup guidance."
        puts "\n3️⃣ Configure your Razorpay API Keys:"
        puts "   Go to **Spree Admin → Configuration → Payment Methods**, add 'Razorpay Checkout',"
        puts "   and enter your **Key ID** and **Key Secret**."
        puts "\n--------------------------------------------------------------------------------\n"
      end
    end
  end
end
