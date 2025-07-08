# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module MempoolSpaceApi
  class Client
    class Error < StandardError; end
    class NotFound < Error; end
    class InvalidRequest < Error; end
    class ServerError < Error; end
    class ConnectionError < Error; end

    BASE_URL = 'https://mempool.space/signet/'

    attr_reader :base_url

    def initialize(base_url = BASE_URL)
      @base_url = base_url
    end

    def address_utxos(address)
      get("api/address/#{address}/utxo")
    end

    def tx_details(txid)
      get("api/tx/#{txid}")
    end

    def broadcast_tx(hex)
      post('api/tx', hex)
    end

    private

    def get(path)
      uri = URI.join(base_url, path)

      response = Net::HTTP.get_response(uri)

      handle_response(response)
    rescue SocketError, Errno::ECONNREFUSED, Timeout::Error => e
      raise ConnectionError, "Failed to connect to mempool API: #{e.message}"
    end

    def post(path, body)
      uri = URI.join(base_url, path)
      request = Net::HTTP::Post.new(uri)
      request.body = body

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      handle_response(response)
    rescue SocketError, Errno::ECONNREFUSED, Timeout::Error => e
      raise ConnectionError, "Failed to connect to mempool API: #{e.message}"
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        parse_body(response)
      when Net::HTTPNotFound
        raise NotFound, "Resource not found: #{response.uri}"
      when Net::HTTPClientError
        raise InvalidRequest, "Invalid request (#{response.code}): #{response.body}"
      when Net::HTTPServerError
        raise ServerError, "Server error (#{response.code}): #{response.body}"
      else
        raise Error, "Unexpected response (#{response.code}): #{response.body}"
      end
    end

    def parse_body(response)
      content_type = response['Content-Type']
      if content_type&.include?('application/json')
        JSON.parse(response.body)
      else
        response.body
      end
    end
  end
end
