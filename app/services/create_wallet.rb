# frozen_string_literal: true

module Services
  class CreateWallet
    include Dry::Transaction

    step :check_presence
    step :create_wallet

    private

    def check_presence(wallet_name:)
      file_path = File.join(BitcoinCLI.config.keys_folder_path, "#{wallet_name}.wif")

      return Failure("#{wallet_name} wallet is already exist") if File.exist?(file_path)

      Success(wallet_name:)
    end

    def create_wallet(wallet_name:)
      key = Bitcoin::Key.generate(compressed: true)
      file_path = File.join(BitcoinCLI.config.keys_folder_path, "#{wallet_name}.wif")
      File.write(file_path, key.to_wif)

      Success(key.to_p2wpkh)
    end
  end
end
