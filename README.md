[![CircleCI](https://circleci.com/gh/coincheckjp/ruby_coincheck_client.svg?style=svg)](https://circleci.com/gh/coincheckjp/ruby_coincheck_client)

# RubyCoincheckClient

This is ruby client implementation for Coincheck API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_coincheck_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby_coincheck_client

## Usage

```ruby
#!/usr/bin/env ruby -Ilib
require 'ruby_coincheck_client'

cc = CoincheckClient.new("YOUR API KEY", "YOUR SECRET KEY")
response = cc.read_balance
response = cc.read_accounts
response = cc.read_transactions
response = cc.read_orders
response = cc.read_orders_rate(order_type: 'buy', amount: "0.01")
response = cc.create_orders(rate: "40001", amount: "0.01", order_type: "buy")
response = cc.create_orders(rate: "50001", amount: "0.001", order_type: "sell")
response = cc.create_orders(market_buy_amount: 100, order_type: "market_buy")
response = cc.create_orders(amount: "0.001", order_type: "market_sell")
response = cc.cancel_order(id: "2503344")
response = cc.create_send_money(address: "136aHpRdd7eezbEusAKS2GyWx9eXZsEuMz", amount: "0.0005")
response = cc.read_send_crypto
response = cc.read_deposits
response = cc.read_ticker
response = cc.read_all_trades
response = cc.read_rate
response = cc.read_order_books
response = cc.read_bank_accounts
response = cc.delete_bank_accounts(id: "2222")
response = cc.read_jpy_withdraws
response = cc.delete_jpy_withdraws
JSON.parse(response.body)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/coincheckjp/ruby_coincheck_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
