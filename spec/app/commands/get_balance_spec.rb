# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commands::GetBalance do
  context 'arguments' do
    it "has 'wallet_name' argument as required" do
      argument = described_class.arguments.find { |a| a.name == :wallet_name }

      expect(argument.options).to include(required: true, type: :string)
    end
  end

  describe '#call' do
    subject(:command) { described_class.new }

    let(:wallet_name) { 'my_wallet' }
    let(:validation_contract) { instance_double(Validations::GetBalanceContract) }
    let(:service) { instance_double(Services::GetBalance) }

    before do
      allow(Validations::GetBalanceContract).to receive(:new).and_return(validation_contract)
      allow(Services::GetBalance).to receive(:new).and_return(service)
    end

    context 'when validation fails' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: true) }

      before do
        message_set = instance_double(Dry::Validation::MessageSet)
        allow(message_set).to receive(:each).and_yield(OpenStruct.new(text: 'wallet_name is missing')).and_return(message_set)
        allow(validation_result).to receive(:errors).with(full: true).and_return(message_set)
        allow(validation_contract).to receive(:call).with(wallet_name: wallet_name).and_return(validation_result)
      end

      it 'prints validation error' do
        expect { command.call(wallet_name: wallet_name) }.to output(/wallet_name is missing/).to_stderr
      end
    end

    context 'when service returns failure' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: false, errors: []) }

      before do
        allow(validation_contract).to receive(:call).and_return(validation_result)
        allow(service).to receive(:call).with(wallet_name: wallet_name).and_return(Dry::Monads::Failure('Wallet not found'))
      end

      it 'prints service error and exits' do
        expect { command.call(wallet_name: wallet_name) }.to output(/Wallet not found/).to_stderr
      end
    end

    context 'when balance is returned successfully' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: false, errors: []) }
      let(:sats_balance) { 123_456_789 }

      before do
        allow(validation_contract).to receive(:call).and_return(validation_result)
        allow(service).to receive(:call).with(wallet_name: wallet_name).and_return(Dry::Monads::Success(sats_balance))
      end

      it 'prints the formatted balance' do
        expect { command.call(wallet_name: wallet_name) }.to output(/#{wallet_name} walet balance is 1.23456789 sBTC/).to_stdout
      end
    end
  end
end
