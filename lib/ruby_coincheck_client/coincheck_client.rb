require 'net/http'
require 'uri'
require 'openssl'
require 'json'

class CoincheckClient

  @@base_url = "https://coincheck.com/"
  @@ssl = true

  def initialize(key = nil, secret = nil, params = {})
    @key = key
    @secret = secret
    if !params[:base_url].nil?
      @@base_url = params[:base_url]
    end
    if !params[:ssl].nil?
      @@ssl = params[:ssl]
    end
  end

  def read_balance
    uri = URI.parse @@base_url + "api/accounts/balance"
    headers = get_signature(uri, @key, @secret)
    result = request_for_get(uri, headers)
    reject_suffixes = ["_debt", "_lent", "_lend_in_use"]
    reject_suffixes.each do |suffix|
      result.reject! { |k, _| k.end_with?(suffix) }
    end
    result
  end

  def read_accounts
    uri = URI.parse @@base_url + "api/accounts"
    headers = get_signature(uri, @key, @secret)
    request_for_get(uri, headers)
  end

  def read_transactions
    uri = URI.parse @@base_url + "api/exchange/orders/transactions"
    headers = get_signature(uri, @key, @secret)
    request_for_get(uri, headers)
  end

  def read_page_transactions
    uri = URI.parse @@base_url + "api/exchange/orders/transactions_pagination"
    headers = get_signature(uri, @key, @secret)
    request_for_get(uri, headers)
  end

  def read_orders(pair: nil)
    uri = URI.parse @@base_url + "api/exchange/orders/opens"
    headers = get_signature(uri, @key, @secret)
    result = request_for_get(uri, headers)
    result["orders"].select! { |o| o["pair"] == pair } if pair
    result
  end

  # order_type: :buy, :sell, :market_buy, :market_sell
  def create_orders(order_type:, rate: nil, amount: nil, market_buy_amount: nil, pair: "btc_jpy")
    body = {
      rate: rate,
      amount: amount,
      market_buy_amount: market_buy_amount,
      order_type: order_type,
      position_id: position_id,
      pair: pair
    }
    uri = URI.parse @@base_url + "api/exchange/orders"
    headers = get_signature(uri, @key, @secret, body.to_json)
    request_for_post(uri, headers, body)
  end

  def cancel_order(id:)
    uri = URI.parse @@base_url + "api/exchange/orders/#{id}"
    headers = get_signature(uri, @key, @secret)
    request_for_delete(uri, headers)
  end

  def cancel_all_orders(pair: nil)
    opens = read_orders(pair: pair)["orders"]
    opens.each do |order|
      cancel_order(id: order["id"])
    end
  end

  # order_type: :buy, :sell
  # price or amount is required
  def read_orders_rate(order_type:, pair: "btc_jpy", price: nil, amount: nil)
    params = { order_type: order_type, pair: pair, price: price, amount: amount }
    uri = URI.parse @@base_url + "api/exchange/orders/rate"
    uri.query = URI.encode_www_form(params)
    request_for_get(uri)
  end

  def create_send_btc(address:, amount:)
    body = {
      address: address,
      amount: amount,
    }
    uri = URI.parse @@base_url + "api/send_money"
    headers = get_signature(uri, @key, @secret, body.to_json)
    request_for_post(uri, headers, body)
  end

  # currency: only Crypto
  def read_send_crypto(currency: "BTC")
    params = { currency: currency }
    uri = URI.parse @@base_url + "api/send_money"
    uri.query = URI.encode_www_form(params)
    headers = get_signature(uri, @key, @secret)
    request_for_get(uri, headers)
  end

  # currency: JPY or Crypto
  def read_deposits(currency: "BTC")
    params = { currency: currency }
    uri = URI.parse @@base_url + "api/deposit_money"
    uri.query = URI.encode_www_form(params)
    headers = get_signature(uri, @key, @secret)
    request_for_get(uri, headers)
  end

  def read_ticker(pair: "btc_jpy")
    params = { pair: pair }
    uri = URI.parse @@base_url + "api/ticker"
    uri.query = URI.encode_www_form(params)
    request_for_get(uri)
  end

  def read_all_trades(pair: "btc_jpy")
    params = { pair: pair }
    uri = URI.parse @@base_url + "api/trades"
    uri.query = URI.encode_www_form(params)
    request_for_get(uri)
  end

  def read_rate(pair: "btc_jpy")
    uri = URI.parse @@base_url + "api/rate/#{pair}"
    request_for_get(uri)
  end

  def read_order_books(pair: "btc_jpy")
    params = { pair: pair }
    uri = URI.parse @@base_url + "api/order_books"
    uri.query = URI.encode_www_form(params)
    request_for_get(uri)
  end

  def read_bank_accounts
    uri = URI.parse @@base_url + "api/bank_accounts"
    headers = get_signature(uri, @key, @secret)
    request_for_get(uri, headers)
  end

  def create_bank_accounts(bank_name:, branch_name:, bank_account_type:, number:, name:)
    body = {
      bank_name: bank_name,
      branch_name: branch_name,
      bank_account_type: bank_account_type,
      number: number,
      name: name
    }
    uri = URI.parse @@base_url + "api/bank_accounts"
    headers = get_signature(uri, @key, @secret, body.to_json)
    request_for_post(uri, headers, body)
  end

  def delete_bank_accounts(id:)
    uri = URI.parse @@base_url + "api/bank_accounts/#{id}"
    headers = get_signature(uri, @key, @secret)
    request_for_delete(uri, headers)
  end

  def read_jpy_withdraws
    uri = URI.parse @@base_url + "api/withdraws"
    headers = get_signature(uri, @key, @secret)
    request_for_get(uri, headers)
  end

  def delete_jpy_withdraws(id:)
    uri = URI.parse @@base_url + "api/withdraws/#{id}"
    headers = get_signature(uri, @key, @secret)
    request_for_delete(uri, headers)
  end

  private
    def http_request(uri, request)
      https = Net::HTTP.new(uri.host, uri.port)
      if @@ssl
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      response = https.start do |h|
        h.request(request)
      end
    end

    def request_for_get(uri, headers = {})
      request = Net::HTTP::Get.new(uri.request_uri, initheader = custom_header(headers))
      res = http_request(uri, request)
      JSON.parse(res.body)
    end

    def request_for_delete(uri, headers)
      request = Net::HTTP::Delete.new(uri.request_uri, initheader = custom_header(headers))
      res = http_request(uri, request)
      JSON.parse(res.body)
    end

    def request_for_post(uri, headers, body)
      request = Net::HTTP::Post.new(uri.request_uri, initheader = custom_header(headers))
      request.body = body.to_json
      res = http_request(uri, request)
      JSON.parse(res.body)
    end

    def custom_header(headers = {})
      headers.merge!({
        "Content-Type" => "application/json",
        "User-Agent" => "RubyCoincheckClient v#{RubyCoincheckClient::VERSION}"
      })
    end

    def get_signature(uri, key, secret, body = "")
      nonce = (Time.now.to_f * 1000000).to_i.to_s
      message = nonce + uri.to_s + body
      signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, message)
      headers = {
        "ACCESS-KEY" => key,
        "ACCESS-NONCE" => nonce,
        "ACCESS-SIGNATURE" => signature
      }
    end
end
