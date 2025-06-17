module SpreeRazorpayCheckout
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_razorpay_checkout'

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'spree_razorpay_checkout.environment', before: :load_config_initializers do |_app|
      SpreeRazorpayCheckout::Config = SpreeRazorpayCheckout::Configuration.new
    end

    initializer 'spree_razorpay_checkout.assets' do |app|
      app.config.assets.paths << root.join('app/javascript')
      app.config.assets.precompile += %w[spree_razorpay_checkout_manifest]
    end

    initializer 'spree_razorpay_checkout.importmap', before: 'importmap' do |app|
      app.config.importmap.paths << root.join('config/importmap.rb')
      app.config.importmap.cache_sweepers << root.join('app/javascript')
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
