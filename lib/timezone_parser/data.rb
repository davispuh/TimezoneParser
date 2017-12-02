# encoding: utf-8
require 'pathname'
require 'set'
require 'tzinfo'
require_relative 'data/storage'

module TimezoneParser
    # Timezone data
    class Data
        # Library Root directory
        RootDir = Pathname.new(__FILE__).realpath.dirname.parent.parent
        # Path to Data directory
        DataDir = RootDir + 'data'
        # Path to Vendor directory
        VendorDir = RootDir + 'vendor'
    end
end
