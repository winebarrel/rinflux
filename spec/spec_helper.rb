$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rinflux'

def rinflux(options = {})
  stubs = Faraday::Adapter::Test::Stubs.new

  Rinflux::Client.new(options) do |faraday|
    faraday.adapter :test, stubs do |stub|
      yield(stub)
    end
  end
end
