# encoding: utf-8
require 'simplecov'

if ENV['CI']
    require 'coveralls'
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end

SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require_relative '../lib/timezone_parser.rb'
