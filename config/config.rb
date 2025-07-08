# frozen_string_literal: true

module BitcoinCLI
  extend Dry::Configurable

  setting :network, default: :signet
  setting :keys_folder_path, default: File.join(File.expand_path('..', __dir__), 'keys')
  setting :fee_in_satoshi, default: 1_000
end
