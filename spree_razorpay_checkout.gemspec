# frozen_string_literal: true

require_relative 'lib/spree_razorpay_checkout/version'

Gem::Specification.new do |spec|
  spec.name        = 'spree_razorpay_checkout'
  spec.version     = SpreeRazorpayCheckout::VERSION
  spec.authors     = ['Your Name'] # TODO: Replace with your name
  spec.email       = ['your.email@example.com'] # TODO: Replace with your email
  spec.homepage    = 'https://github.com/yourusername/spree_razorpay_checkout' # TODO: Update
    spec.summary     = 'Razorpay payment gateway for Spree Commerce.'
    spec.description = 'Integrates Razorpay payment gateway with Spree Commerce, allowing for seamless payments.'
    spec.license     = 'BSD-3-Clause'
    
    spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0') # Adjust as needed
    
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    # spec.metadata['changelog_uri'] = 'TODO: Put your gem\'s CHANGELOG.md URL here.'
  
    spec.files = Dir["{app,config,db,lib,vendor}/**/*"].reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
    spec.bindir        = 'exe'
    spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
    spec.require_paths = ['lib']
    
    # Spree Dependencies
    spec.add_dependency 'spree', '>= 5.1.0.beta'
    spec.add_dependency 'spree_storefront', '>= 5.1.0.beta'
    spec.add_dependency 'spree_admin', '>= 5.1.0.beta'
    spec.add_dependency 'spree_extension'
    
    # Razorpay SDK Dependency
    spec.add_dependency 'razorpay', '~> 1.1' # TODO: Check for the latest stable Razorpay SDK version
    
    # Development dependencies (optional, for testing etc.)
    # spec.add_development_dependency 'spree_dev_tools'
  end