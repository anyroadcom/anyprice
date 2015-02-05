require 'bundler/setup'
Bundler.setup

require 'pry'
require 'pricing_definition'

RSpec.configure do |config|
  config.order = "random"
end
