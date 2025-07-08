# frozen_string_literal: true

module Commands
  class SendToAddress < Dry::CLI::Command
    include Helpers::BitcoinUnits

    desc 'Send to an address'

    argument :wallet_name, type: :string, required: true, desc: 'Wallet name'
    argument :address, type: :string, required: true, desc: 'Address of a wallet to send money to'
    argument :amount, type: :string,  required: true, desc: 'Money amount'

    def call(wallet_name:, address:, amount:, **_options)
      result = Validations::SendToAddressContract.new.call(wallet_name:, address:, amount:)
      result.errors(full: true).each { |err| warn err.text } and return if result.failure?

      result = Services::SendToAddress.new.call(wallet_name:, address:, amount: btc_to_sats(amount))

      if result.failure?
        warn result.failure
        return
      end

      puts 'crypto is succesfully sent'
    end
  end
end
