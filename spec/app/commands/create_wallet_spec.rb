# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commands::CreateWallet do
  context 'arguments' do
    it "has 'wallet_name' argument as required" do
      argument = described_class.arguments.find { |a| a.name == :wallet_name }

      expect(argument.options).to include(required: true, type: :string)
    end
  end

  describe '#call' do
    subject(:command) { described_class.new }

    let(:wallet_name) { 'test_wallet' }
    let(:validation_contract) { instance_double(Validations::CreateWalletContract) }
    let(:service) { instance_double(Services::CreateWallet) }

    before do
      allow(Validations::CreateWalletContract).to receive(:new).and_return(validation_contract)
      allow(Services::CreateWallet).to receive(:new).and_return(service)
    end

    context 'when validation fails' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: true) }

      before do
        message_set = instance_double(Dry::Validation::MessageSet)
        allow(message_set).to receive(:each).and_yield(OpenStruct.new(text: 'wallet_name is required')).and_return(message_set)
        allow(validation_result).to receive(:errors).with(full: true).and_return(message_set)
        allow(validation_contract).to receive(:call).with(wallet_name: wallet_name).and_return(validation_result)
      end

      it 'prints validation error' do
        expect { command.call(wallet_name: wallet_name) }.to output(/wallet_name is required/).to_stderr
      end
    end

    context 'when wallet creation fails' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: false, errors: []) }

      before do
        allow(validation_contract).to receive(:call).and_return(validation_result)
        allow(service).to receive(:call).with(wallet_name: wallet_name).and_return(Dry::Monads::Failure('Something went wrong'))
      end

      it 'prints error from the service and exits' do
        expect { command.call(wallet_name: wallet_name) }.to output(/Something went wrong/).to_stderr
      end
    end

    context 'when wallet is created successfully' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: false, errors: []) }
      let(:address) { 'bcrt1qabc123' }

      before do
        allow(validation_contract).to receive(:call).and_return(validation_result)
        allow(service).to receive(:call).with(wallet_name: wallet_name).and_return(Dry::Monads::Success(address))
      end

      it 'prints success message with address' do
        expect { command.call(wallet_name: wallet_name) }.to output(/#{wallet_name} wallet is created. Address: #{address}/).to_stdout
      end
    end
  end
end
