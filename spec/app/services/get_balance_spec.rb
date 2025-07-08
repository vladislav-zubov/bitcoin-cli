# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::GetBalance do
  subject(:service) { described_class.new }

  let(:wallet_name) { 'test_wallet' }
  let(:keys_path) { '/fake/keys' }
  let(:wallet_path) { File.join(keys_path, "#{wallet_name}.wif") }
  let(:client) { instance_double(MempoolSpaceApi::Client) }
  let(:fake_key) do
    instance_double(Bitcoin::Key, to_p2wpkh: 'address')
  end

  before do
    allow(BitcoinCLI).to receive_message_chain(:config, :keys_folder_path).and_return(keys_path)
  end

  describe '#call' do
    context 'when wallet file does not exist' do
      before do
        allow(File).to receive(:read).with(wallet_path).and_raise(Errno::ENOENT.new('No such file'))
      end

      it 'returns Failure with load_wallet_key error' do
        result = service.call(wallet_name:)
        expect(result).to be_failure
        expect(result.failure).to match(/load_wallet_key error: Errno::ENOENT/)
      end
    end

    context 'when utxo API fails' do
      before do
        allow(File).to receive(:read).with(wallet_path).and_return('fake_wif')
        allow(Bitcoin::Key).to receive(:from_wif).with('fake_wif').and_return(fake_key)
        allow(MempoolSpaceApi::Client).to receive(:new).and_return(client)
        allow(client).to receive(:address_utxos).and_raise(MempoolSpaceApi::Client::ServerError.new('API down'))
      end

      it 'returns Failure with get_utxos error' do
        result = service.call(wallet_name:)
        expect(result).to be_failure
        expect(result.failure).to match(/get_utxos error: MempoolSpaceApi::Client::ServerError/)
      end
    end

    context 'when everything succeeds' do
      let(:utxos) do
        [
          { 'txid' => 'abc', 'value' => 1_000 },
          { 'txid' => 'def', 'value' => 2_000 }
        ]
      end

      before do
        allow(File).to receive(:read).with(wallet_path).and_return('fake_wif')
        allow(Bitcoin::Key).to receive(:from_wif).with('fake_wif').and_return(fake_key)
        allow(MempoolSpaceApi::Client).to receive(:new).and_return(client)
        allow(client).to receive(:address_utxos).with('address').and_return(utxos)
      end

      it 'returns the total balance' do
        result = service.call(wallet_name:)
        expect(result).to be_success
        expect(result.value!).to eq(3_000)
      end
    end
  end
end
