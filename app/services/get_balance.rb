# frozen_string_literal: true

module Services
  class GetBalance
    include Dry::Transaction

    step :load_wallet_key
    step :get_utxos
    step :calculate_balance

    private

    def load_wallet_key(wallet_name:)
      file_path = File.join(BitcoinCLI.config.keys_folder_path, "#{wallet_name}.wif")

      file_data = File.read(file_path)
      key = Bitcoin::Key.from_wif(file_data)

      Success(key:)
    rescue Errno::ENOENT => e
      Failure("load_wallet_key error: #{e.class} - #{e.message}")
    end

    def get_utxos(key:)
      utxos = MempoolSpaceApi::Client.new.address_utxos(key.to_p2wpkh)

      Success(utxos:)
    rescue MempoolSpaceApi::Client::Error => e
      Failure("get_utxos error: #{e.class} - #{e.message}")
    end

    def calculate_balance(utxos:)
      balance = utxos.sum { |u| u['value'] }

      Success(balance)
    end
  end
end
