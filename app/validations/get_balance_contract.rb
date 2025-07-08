# frozen_string_literal: true

module Validations
  class GetBalanceContract < Dry::Validation::Contract
    params do
      required(:wallet_name).filled(:string)
    end
  end
end
