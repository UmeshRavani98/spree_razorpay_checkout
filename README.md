# Spree RazorPay Checkout

This is the Unofficial RazorPay Checkout extension for [Spree Commerce](https://spreecommerce.org).

## Installation

1. Add this extension to your Gemfile with this line:

    ```ruby
    gem 'spree_razorpay_checkout', git: 'https://github.com/umeshravani/spree_razorpay_checkout'
    ```
2. Install Bundle using this command:

    ```ruby
    bundle install
    ```    
3. Run the install generator

    ```ruby
    bundle exec rails g spree_razorpay_checkout:install
    ```
4. Run Migrations when asked "Would you like to run the migrations now? [Y/n]"
    ```ruby
    Y
    ```
5. Restart your server

  If your server was running, restart it so that it can find the assets properly.

## Developing

1. Create a dummy app

    ```bash
    bundle update
    bundle exec rake test_app
    ```

2. Add your new code
3. Run tests

    ```bash
    bundle exec rspec
    ```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_razorpay_checkout/factories'
```

## Releasing a new version

```shell
bundle exec gem bump -p -t
bundle exec gem release
```

For more options please see [gem-release README](https://github.com/svenfuchs/gem-release)

## Contributing

If you'd like to contribute, please take a look at the
[instructions](CONTRIBUTING.md) for installing dependencies and crafting a good
pull request.
