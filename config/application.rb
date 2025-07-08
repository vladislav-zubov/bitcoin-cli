# frozen_string_literal: true

require_relative 'config'

Dir[File.join(__dir__, '../config/initializers/*.rb')].sort.each { |file| require file }

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../app")
loader.push_dir("#{__dir__}/../lib")
loader.setup
