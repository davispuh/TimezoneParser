# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe '.preload' do
        it 'should preload data files' do
            expect(TimezoneParser.preload).to be_true
        end
    end
end
