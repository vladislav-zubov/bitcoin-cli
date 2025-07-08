# frozen_string_literal: true

module Commands
  class Version < Dry::CLI::Command
    VERSION = '1.0.0'

    desc 'Print version'

    def call(*)
      puts VERSION
    end
  end
end
