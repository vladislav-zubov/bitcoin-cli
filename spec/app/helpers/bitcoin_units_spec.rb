# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Helpers::BitcoinUnits do
  subject(:helper) { Object.new.extend(described_class) }

  describe '#sats_to_btc' do
    it 'converts 123456789 satoshi to 1.23456789 BTC' do
      expect(helper.sats_to_btc(123_456_789)).to eq('1.23456789')
    end
  end

  describe '#btc_to_sats' do
    it 'converts 1.23456789 BTC to 123456789 satoshi' do
      expect(helper.btc_to_sats('1.23456789')).to eq(123_456_789)
    end
  end
end
