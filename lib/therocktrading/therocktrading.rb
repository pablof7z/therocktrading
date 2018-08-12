require 'rest-client'
require 'json'
require 'base64'
require 'byebug'

module Therocktrading
  class API
    attr_reader :key,
                :secret,
                :url

    def initialize(key:, secret:, url: 'https://api.therocktrading.com/v1/')
      @key = key
      @secret = secret
      @url = url
    end

    def balances
      get('balances')
    end

    def address(currency)
      get("currencies/#{currency}/addresses")
    end

    def new_address(currency, params = {})
      post("currencies/#{currency}/addresses", payload: params)
    end

    def create_order(fund_id:, side:, amount:, price:)
      post("funds/#{fund_id}/orders", payload: {
        fund_id: fund_id,
        side: side,
        amount: amount,
        price: price,
      }, exception: Therocktrading::CreateOrderException)
    end

    def order(fund_id:, id:)
      get("funds/#{fund_id}/orders/#{id}")
    end

    def cancel_order(fund_id:, id:)
      delete("funds/#{fund_id}/orders/#{id}", exception: Therocktrading::CancelOrderException)
    end

    def withdrawal(currency:, address:, amount:)
      opts = {
        currency: currency,
        amount: amount,
        destination_address: address,
      }
      post('atms/withdraw', payload: opts, exception: Therocktrading::WithdrawalException)
    end

    def orders(fund_id:)
      get("funds/#{fund_id}/orders")
    end

    def trades(fund_id:)
      get("funds/#{fund_id}/trades")
    end

    def transactions(id)
      get("transactions/#{id}")
    end

    private

    def signature(path, params, nonce)
      data = "#{nonce}#{@url}#{path}"

      OpenSSL::HMAC.hexdigest('sha512', @secret, data)
    end

    def get(path, opts = {})
      uri = URI.parse("#{@url}#{path}")
      uri.query = URI.encode_www_form(opts[:params]) if opts[:params]

      response = RestClient.get(uri.to_s, auth_headers(path, opts))

      if !opts[:skip_json]
        JSON.parse(response.body)
      else
        response.body
      end
    end

    def post(path, payload: {}, exception: RuntimeError)
      data = JSON.unparse(payload)
      response = RestClient.post("#{@url}#{path}", data, auth_headers(path, payload))

      if !response.body.empty?
        JSON.parse(response.body)
      elsif response.code < 200 || response.code >= 300
        debugger
        raise response.code
      else
        nil
      end
    rescue RestClient::UnprocessableEntity => e
      handle_exception(exception, e)
    end

    def delete(path, payload: {}, exception: RuntimeError)
      response = RestClient.delete("#{@url}#{path}", auth_headers(path, payload))

      if !response.body.empty?
        JSON.parse(response.body)
      elsif response.code < 200 || response.code >= 300
        debugger
        raise response.code
      else
        nil
      end
    rescue RestClient::UnprocessableEntity => e
      handle_exception(exception, e)
    end

    def handle_exception(exception, e)
      error = JSON.parse(e.response.body) rescue nil
      error = error['errors'].map{|e| e['message']}.join(' ') if error && error['errors']
      error ||= e.response.inspect
      raise exception, error
    end

    def auth_headers(path, params)
      nonce = (Time.now.utc.to_f * 1000).to_i

      {
        'Content-Type' => 'application/json',
        'X-TRT-KEY' => @key,
        'X-TRT-SIGN' => signature(path, params, nonce),
        'X-TRT-NONCE' => nonce
      }
    end
  end
end
