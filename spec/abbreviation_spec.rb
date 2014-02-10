# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe TimezoneParser::Abbreviation do
        describe '#new' do
            it 'should be an instance of a Abbreviation class' do
                expect(TimezoneParser::Abbreviation.new('CET')).to be_an_instance_of TimezoneParser::Abbreviation
            end
        end

        describe '#isValid?' do
            it 'should be valid abbreviation' do
                expect(TimezoneParser::Abbreviation.new('CET').isValid?).to be_true
            end

            it 'should not be valid abbreviation' do
                expect(TimezoneParser::Abbreviation.new('LOL').isValid?).to be_false
            end

            it 'should be valid case-insensitive abbreviation' do
                expect(TimezoneParser::Abbreviation.new('Pst').isValid?).to be_true
            end
        end

        describe '#getOffsets' do
            it 'should return offsets for CET abbreviation' do
                expect(TimezoneParser::Abbreviation.new('CET').getOffsets).to eq([3600])
            end

            it 'should return offsets for WEZ abbreviation' do
                expect(TimezoneParser::Abbreviation.new('WEZ').getOffsets).to eq([0, 3600])
            end

            context 'before specified time' do
                it 'should return correct offsets' do
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('1982-04-30T20:59:59+00:00')).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('1982-04-30T21:00:00+00:00')).getOffsets).to eq([-10800, 14400])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('1982-09-30T19:59:59+00:00')).getOffsets).to eq([-10800, 14400])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('1982-09-30T20:00:00+00:00')).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('1982-09-30T20:00:01+00:00')).getOffsets).to eq([-10800])
                end
            end

            context 'in specified region' do
                it 'should return correct offsets' do
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('2007-04-01T00:00:00+00:00'), []).getOffsets).to eq([-10800, 14400])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('2007-04-01T00:00:00+00:00'), ['IQ']).getOffsets).to eq([14400])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('2007-04-01T00:00:00+00:00'), ['GL']).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(DateTime.parse('2007-09-30T23:59:59+00:00'), ['IQ', 'CA']).getOffsets).to eq([-10800, 14400])
                end
            end

            context 'with specified type' do
                it 'should return correct offsets' do
                    expect(TimezoneParser::Abbreviation.new('HAT').set(DateTime.parse('2014-02-05T10:00:00+00:00'), nil ).getOffsets).to eq([-36000, -32400, -12600])
                    expect(TimezoneParser::Abbreviation.new('HAT').set(DateTime.parse('2014-04-05T10:00:00+00:00'), nil ).getOffsets).to eq([-36000, -32400, -9000])
                    expect(TimezoneParser::Abbreviation.new('HAT').set(DateTime.parse('2014-02-05T10:00:00+00:00'), nil, :standard ).getOffsets).to eq([-36000, -12600])
                    expect(TimezoneParser::Abbreviation.new('HAT').set(DateTime.parse('2014-02-05T10:00:00+00:00'), nil, :daylight ).getOffsets).to eq([-36000, -32400, -12600])
                    expect(TimezoneParser::Abbreviation.new('HAT').set(DateTime.parse('2014-04-05T10:00:00+00:00'), nil, :standard ).getOffsets).to eq([-36000, -32400, -9000])
                    expect(TimezoneParser::Abbreviation.new('HAT').set(DateTime.parse('2014-04-05T10:00:00+00:00'), nil, :daylight ).getOffsets).to eq([-36000, -32400, -9000])
                end
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for KMT abbreviation' do
                expect(TimezoneParser::Abbreviation.new('KMT').getTimezones).to eq(['Europe/Kiev'])
            end
        end

        describe '#getMetazones' do
            it 'should return all metazones for HAT abbreviation' do
                expect(TimezoneParser::Abbreviation.new('HAT').getMetazones).to eq(['Hawaii_Aleutian', 'Newfoundland'])
            end
        end
    end

end
