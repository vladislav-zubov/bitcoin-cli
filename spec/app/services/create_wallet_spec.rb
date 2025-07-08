# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::CreateWallet do
  subject(:service) { described_class.new }

  let(:wallet_name) { 'test_wallet' }
  let(:keys_path) { '/fake/path/keys' }
  let(:wallet_path) { File.join(keys_path, "#{wallet_name}.wif") }
  let(:fake_key) { instance_double(Bitcoin::Key, to_wif: 'fake_wif_string', to_p2wpkh: 'fake_address') }

  before do
    allow(BitcoinCLI).to receive_message_chain(:config, :keys_folder_path).and_return(keys_path)
  end

  describe '#call' do
    context 'when wallet already exists' do
      before do
        allow(File).to receive(:exist?).with(wallet_path).and_return(true)
      end

      it 'returns Failure' do
        result = service.call(wallet_name:)
        expect(result).to be_failure
        expect(result.failure).to eq("#{wallet_name} wallet is already exist")
      end
    end

    context 'when wallet does not exist' do
      before do
        allow(File).to receive(:exist?).with(wallet_path).and_return(false)
        allow(Bitcoin::Key).to receive(:generate).with(compressed: true).and_return(fake_key)
        allow(File).to receive(:write).with(wallet_path, 'fake_wif_string')
      end

      it 'generates wallet and returns address' do
        result = service.call(wallet_name:)

        expect(result).to be_success
        expect(result.value!).to eq('fake_address')
        expect(File).to have_received(:write).with(wallet_path, 'fake_wif_string')
      end
    end
  end
end
