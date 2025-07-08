# frozen_string_literal: true

module Commands
  class GetBalance < Dry::CLI::Command
    include Helpers::BitcoinUnits

    desc 'Get balance of a wallet'

    argument :wallet_name, type: :string, required: true, desc: 'Wallet name'

    def call(wallet_name:, **_options)
      result = Validations::GetBalanceContract.new.call(wallet_name:)
      result.errors(full: true).each { |err| warn err.text } and return if result.failure?

      result = Services::GetBalance.new.call(wallet_name:)

      if result.failure?
        warn result.failure
        return
      end

      puts "#{wallet_name} walet balance is #{sats_to_btc(result.value!)} sBTC"
    end
  end
end
