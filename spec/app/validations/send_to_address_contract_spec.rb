# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Validations::SendToAddressContract do
  subject(:contract) { described_class.new }

  before { Bitcoin.chain_params = :signet }

  describe '#call' do
    let(:valid_address) { 'tb1qsge6nm4htef9fjsh4xhm67fcc6e0rjn5ns82zr' }
    let(:invalid_address) { 'not-a-bitcoin-address' }

    let(:valid_input) do
      {
        wallet_name: 'wallet1',
        address: valid_address,
        amount: 0.001
      }
    end

    it 'passes with valid input' do
      result = contract.call(valid_input)
      expect(result).to be_success
    end

    it 'fails when required fields are missing' do
      result = contract.call({})
      expect(result).to be_failure
      expect(result.errors.to_h.keys).to include(:wallet_name, :address, :amount)
    end

    it 'fails with non-float amount' do
      result = contract.call(valid_input.merge(amount: '0.001fff'))
      expect(result).to be_failure
      expect(result.errors[:amount]).to include('must be a float')
    end

    it 'fails with invalid bitcoin address' do
      result = contract.call(valid_input.merge(address: invalid_address))
      expect(result).to be_failure
      expect(result.errors[:address]).to include('is not a valid Bitcoin address')
    end
  end
end
