# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Validations::CreateWalletContract do
  subject(:contract) { described_class.new }

  describe '#call' do
    it 'passes with valid input' do
      result = contract.call({ wallet_name: 'my_wallet' })
      expect(result).to be_success
    end

    it 'fails with empty string' do
      result = contract.call({ wallet_name: '' })
      expect(result).to be_failure
      expect(result.errors[:wallet_name]).to include('must be filled')
    end

    it 'fails with missing wallet_name' do
      result = contract.call({})
      expect(result).to be_failure
      expect(result.errors[:wallet_name]).to include('is missing')
    end
  end
end
