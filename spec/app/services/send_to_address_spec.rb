# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::SendToAddress do
  subject(:service) { described_class.new }

  let(:wallet_name) { 'wallet1' }
  let(:amount) { 10_000 }
  let(:keys_path) { '/fake/keys' }
  let(:wallet_path) { File.join(keys_path, "#{wallet_name}.wif") }
  let(:mempool_client) { instance_double(MempoolSpaceApi::Client) }

  let(:wallet_key_wif) { 'cP2hv2JbwU11wasB43awqLvXK9aGJnwDwwTNk53Go32WYRSykeQe' }
  let(:address) { 'tb1q8yvkd5m6xzxt4kc8yd5ukccjwgwylfhs96c08y' }

  let(:utxos) do
    [
      { 'txid' => 'abc123', 'vout' => 0, 'value' => 20_000 }
    ]
  end

  let(:tx_details) do
    {
      'vout' => [
        {
          'scriptpubkey' => '0014f8c73aa3dd0d26da8c6f4b2333c15c2b27e15459'
        }
      ]
    }
  end

  before do
    allow(BitcoinCLI).to receive_message_chain(:config, :keys_folder_path).and_return(keys_path)
    allow(BitcoinCLI).to receive_message_chain(:config, :fee_in_satoshi).and_return(1_000)
    allow(File).to receive(:read).with(wallet_path).and_return(wallet_key_wif)
    allow(MempoolSpaceApi::Client).to receive(:new).and_return(mempool_client)
    allow(mempool_client).to receive(:address_utxos).and_return(utxos)
    allow(mempool_client).to receive(:tx_details).and_return(tx_details)
    allow(mempool_client).to receive(:broadcast_tx).and_return(true)
  end

  it 'returns success when all steps pass' do
    result = service.call(wallet_name:, address:, amount:)
    expect(result).to be_success
    expect(result.value!).to eq(:ok)
  end

  context 'when wallet file is missing' do
    before do
      allow(File).to receive(:read).and_raise(Errno::ENOENT.new('no file'))
    end

    it 'returns failure from load_wallet_key' do
      result = service.call(wallet_name:, address:, amount:)
      expect(result).to be_failure
      expect(result.failure).to match(/load_wallet_key error/)
    end
  end

  context 'when API fails during tx lookup' do
    before do
      allow(mempool_client).to receive(:address_utxos).and_return(utxos)
      allow(mempool_client).to receive(:tx_details).and_raise(MempoolSpaceApi::Client::ServerError.new('fail'))
    end

    it 'returns failure from load_txs' do
      result = service.call(wallet_name:, address:, amount:)
      expect(result).to be_failure
      expect(result.failure).to match(/load_txs error/)
    end
  end

  context 'when balance is not enough' do
    let(:utxos) do
      [{ 'txid' => 'abc123', 'vout' => 0, 'value' => 5_000 }]
    end

    it 'returns failure from build_transaction' do
      result = service.call(wallet_name:, address:, amount:)
      expect(result).to be_failure
      expect(result.failure).to eq('Not enogh crypto in the wallet')
    end
  end

  context 'when broadcast fails' do
    before do
      allow(mempool_client).to receive(:broadcast_tx).and_raise(MempoolSpaceApi::Client::Error.new('fail'))
    end

    it 'returns failure from broadcast_transaction' do
      result = service.call(wallet_name:, address:, amount:)
      expect(result).to be_failure
      expect(result.failure).to match(/broadcast_transaction error/)
    end
  end
end
