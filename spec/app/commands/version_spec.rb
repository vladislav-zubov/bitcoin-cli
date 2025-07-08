# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commands::Version do
  describe '#call' do
    it 'prints a version to a stdout' do
      expect { described_class.new.call }.to output(include(described_class::VERSION)).to_stdout
    end
  end
end
