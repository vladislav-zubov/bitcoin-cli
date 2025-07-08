# frozen_string_literal: true

module Commands
  class CreateWallet < Dry::CLI::Command
    desc 'Create a new wallet'

    argument :wallet_name, type: :string, required: true, desc: 'Wallet name'

    example ['my-cool-wallet']

    def call(wallet_name:, **)
      result = Validations::CreateWalletContract.new.call(wallet_name: wallet_name)
      result.errors(full: true).each { |err| warn err.text } and return if result.failure?

      result = Services::CreateWallet.new.call(wallet_name:)

      if result.failure?
        warn(result.failure)
        return
      end

      puts "#{wallet_name} wallet is created. Address: #{result.value!}"
    end
  end
end
