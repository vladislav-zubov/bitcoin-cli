# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commands::SendToAddress do
  context 'arguments' do
    it "has 'wallet_name' argument as required" do
      argument = described_class.arguments.find { |a| a.name == :wallet_name }

      expect(argument.options).to include(required: true, type: :string)
    end

    it "has 'address' argument as required" do
      argument = described_class.arguments.find { |a| a.name == :address }

      expect(argument.options).to include(required: true, type: :string)
    end

    it "has 'amount' argument as required" do
      argument = described_class.arguments.find { |a| a.name == :amount }

      expect(argument.options).to include(required: true, type: :string)
    end
  end

  describe '#call' do
    subject(:command) { described_class.new }

    let(:wallet_name) { 'wallet1' }
    let(:address) { 'bcrt1qvalidaddress' }
    let(:amount) { '0.12345678' }
    let(:sats_amount) { 12_345_678 }
    let(:validation_contract) { instance_double(Validations::SendToAddressContract) }
    let(:service) { instance_double(Services::SendToAddress) }

    before do
      allow(Validations::SendToAddressContract).to receive(:new).and_return(validation_contract)
      allow(Services::SendToAddress).to receive(:new).and_return(service)
    end

    context 'when validation fails' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: true) }

      before do
        message_set = instance_double(Dry::Validation::MessageSet)
        allow(message_set).to receive(:each).and_yield(OpenStruct.new(text: 'amount must be greater than 0')).and_return(message_set)
        allow(validation_result).to receive(:errors).with(full: true).and_return(message_set)
        allow(validation_contract).to receive(:call).with(wallet_name: wallet_name, address: address, amount: amount).and_return(validation_result)
      end

      it 'prints validation error' do
        expect { command.call(wallet_name: wallet_name, address: address, amount: amount) }.to output(/amount must be greater than 0/).to_stderr
      end
    end

    context 'when sending fails' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: false, errors: []) }

      before do
        allow(validation_contract).to receive(:call).and_return(validation_result)
        allow(command).to receive(:btc_to_sats).with(amount).and_return(sats_amount)
        allow(service).to receive(:call).with(wallet_name: wallet_name, address: address, amount: sats_amount).and_return(Dry::Monads::Failure('Transaction failed'))
      end

      it 'prints service error' do
        expect { command.call(wallet_name: wallet_name, address: address, amount: amount) }.to output(/Transaction failed/).to_stderr
      end
    end

    context 'when sending is successful' do
      let(:validation_result) { instance_double(Dry::Validation::Result, failure?: false, errors: []) }

      before do
        allow(validation_contract).to receive(:call).and_return(validation_result)
        allow(command).to receive(:btc_to_sats).with(amount).and_return(sats_amount)
        allow(service).to receive(:call).with(wallet_name: wallet_name, address: address, amount: sats_amount).and_return(Dry::Monads::Success(true))
      end

      it 'prints success message' do
        expect { command.call(wallet_name: wallet_name, address: address, amount: amount) }.to output(/crypto is succesfully sent/).to_stdout
      end
    end
  end
end
