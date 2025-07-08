# frozen_string_literal: true

module Helpers
  module BitcoinUnits
    SATOSHIS_PER_BTC = 100_000_000

    def sats_to_btc(sats)
      (BigDecimal(sats.to_s) / SATOSHIS_PER_BTC).to_s('F')
    end

    def btc_to_sats(btc)
      (BigDecimal(btc.to_s) * SATOSHIS_PER_BTC).to_i
    end
  end
end
