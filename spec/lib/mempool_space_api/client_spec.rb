# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MempoolSpaceApi::Client do
  subject(:client) { described_class.new }

  let(:base_url) { MempoolSpaceApi::Client::BASE_URL }

  describe '#address_utxos' do
    let(:address) { 'address' }
    let(:utxo) do
      {
        'txid' => 'txid',
        'vout' => 1,
        'value' => 325_069,
        'status' => {
          'confirmed' => true,
          'block_height' => 259_655
        }
      }
    end
    let(:url) { "#{base_url}api/address/#{address}/utxo" }

    it 'returns array of UTXOs' do
      stub_request(:get, url).to_return(status: 200, body: [utxo].to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.address_utxos(address)

      expect(result.first).to include(
        'txid' => utxo['txid'],
        'value' => utxo['value']
      )
    end

    it 'raises NotFound for 404' do
      stub_request(:get, url).to_return(status: 404)

      expect { client.address_utxos(address) }.to raise_error(MempoolSpaceApi::Client::NotFound)
    end
  end

  describe '#tx_details' do
    let(:txid) { 'txid' }
    let(:url) { "#{base_url}api/tx/#{txid}" }
    let(:tx_response) do
      {
        'txid' => txid,
        'fee' => 1000,
        'vin' => [
          { 'txid' => 'vin_txid', 'vout' => 1 }
        ],
        'vout' => [
          { 'value' => 1000 },
          { 'value' => 325_069 }
        ],
        'status' => { 'confirmed' => true, 'block_height' => 259_655 }
      }
    end

    it 'returns transaction details' do
      stub_request(:get, url).to_return(status: 200, body: tx_response.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.tx_details(txid)

      expect(result).to include(
        'txid' => txid,
        'fee' => 1000,
        'status' => hash_including('confirmed' => true)
      )
    end

    it 'raises NotFound for 404' do
      stub_request(:get, url).to_return(status: 404)

      expect { client.tx_details(txid) }.to raise_error(MempoolSpaceApi::Client::NotFound)
    end
  end

  describe '#broadcast_tx' do
    let(:hex) { 'hex' }
    let(:url) { "#{base_url}api/tx" }

    it 'returns plain response string on success' do
      stub_request(:post, url).to_return(status: 200, body: 'ok', headers: { 'Content-Type' => 'text/plain' })

      result = client.broadcast_tx(hex)
      expect(result).to eq('ok')
    end

    it 'raises InvalidRequest for 400' do
      stub_request(:post, url).to_return(status: 400, body: 'bad tx')

      expect { client.broadcast_tx(hex) }.to raise_error(MempoolSpaceApi::Client::InvalidRequest)
    end
  end

  describe 'error handling' do
    let(:txid) { 'txid' }
    let(:url) { "#{base_url}api/tx/#{txid}" }

    it 'raises ConnectionError on network failure' do
      stub_request(:get, url).to_raise(SocketError.new('unreachable'))

      expect { client.tx_details(txid) }.to raise_error(MempoolSpaceApi::Client::ConnectionError)
    end

    it 'raises ServerError for 500' do
      stub_request(:get, url).to_return(status: 500, body: 'internal error')

      expect { client.tx_details(txid) }.to raise_error(MempoolSpaceApi::Client::ServerError)
    end
  end
end
