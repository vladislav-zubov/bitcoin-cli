# frozen_string_literal: true

module Services
  class SendToAddress
    include Dry::Transaction

    step :load_wallet_key
    step :load_txs
    step :build_transaction
    step :sign_transaction
    step :broadcast_transaction

    private

    def load_wallet_key(wallet_name:, address:, amount:)
      file_path = File.join(BitcoinCLI.config.keys_folder_path, "#{wallet_name}.wif")

      file_data = File.read(file_path)
      key = Bitcoin::Key.from_wif(file_data)

      Success(address:, amount:, key:)
    rescue Errno::ENOENT => e
      Failure("load_wallet_key error: #{e.class} - #{e.message}")
    end

    def load_txs(address:, amount:, key:)
      mempool_client = MempoolSpaceApi::Client.new
      utxos = mempool_client.address_utxos(key.to_p2wpkh)

      txs_details = utxos.map do |utxo|
        details = mempool_client.tx_details(utxo['txid'])

        utxo.slice('txid', 'vout', 'value').merge(details['vout'][utxo['vout']].slice('scriptpubkey'))
      end

      Success(address:, amount:, key:, txs_details:)
    rescue MempoolSpaceApi::Client::Error => e
      Failure("load_txs error: #{e.class} - #{e.message}")
    end

    def build_transaction(address:, amount:, key:, txs_details:)
      transaction = Bitcoin::Tx.new

      add_transaction_inputs(transaction, txs_details)
      add_transaction_outputs(transaction, amount, address)

      total_input = txs_details.sum { |u| u['value'] }
      change = total_input - amount - BitcoinCLI.config.fee_in_satoshi

      return Failure('Not enogh crypto in the wallet') if change.negative?

      add_transaction_change(transaction, key, change) if change.positive?

      Success(key:, txs_details:, transaction:)
    end

    def sign_transaction(key:, txs_details:, transaction:)
      txs_details.each_with_index do |tx, index|
        script_code = Bitcoin::Script.parse_from_payload(tx['scriptpubkey'].htb)
        sighash = transaction.sighash_for_input(
          index,
          script_code,
          sig_version: :witness_v0,
          amount: tx['value']
        )
        sig = key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
        transaction.inputs[index].script_witness.stack << sig << key.pubkey.htb
      end

      Success(transaction:)
    end

    def broadcast_transaction(transaction:)
      MempoolSpaceApi::Client.new.broadcast_tx(transaction.to_hex)

      Success(:ok)
    rescue MempoolSpaceApi::Client::Error => e
      Failure("broadcast_transaction error: #{e.class} - #{e.message}")
    end

    def add_transaction_inputs(transaction, txs_details)
      txs_details.each do |tx|
        transaction.inputs << Bitcoin::TxIn.new(
          out_point: Bitcoin::OutPoint.from_txid(tx['txid'], tx['vout'])
        )
      end
    end

    def add_transaction_outputs(transaction, amount, address)
      transaction.outputs << Bitcoin::TxOut.new(
        value: amount,
        script_pubkey: Bitcoin::Script.parse_from_addr(address)
      )
    end

    def add_transaction_change(transaction, key, change)
      transaction.outputs << Bitcoin::TxOut.new(
        value: change,
        script_pubkey: Bitcoin::Script.parse_from_addr(key.to_p2wpkh)
      )
    end
  end
end
