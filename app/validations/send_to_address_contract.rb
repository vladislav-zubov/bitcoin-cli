# frozen_string_literal: true

module Validations
  class SendToAddressContract < Dry::Validation::Contract
    params do
      required(:wallet_name).filled(:string)
      required(:address).filled(:string)
      required(:amount).filled(:float)
    end

    rule(:address) do
      Bitcoin::Script.parse_from_addr(value)
    rescue ArgumentError
      key.failure('is not a valid Bitcoin address')
    end

    rule(:amount) do
      key.failure('must be greater than 0') if value <= 0
    end
  end
end
