# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe TimezoneParser::Abbreviation do
        describe '#new' do
            it 'should not raise error' do
                expect { TimezoneParser::Abbreviation.new('CET') }.not_to raise_error
            end
        end

        describe '#isValid?' do
            it 'should be valid abbreviation' do
                expect(TimezoneParser::Abbreviation.new('CET').isValid?).to be true
            end

            it 'should not be valid abbreviation' do
                expect(TimezoneParser::Abbreviation.new('LOL').isValid?).to be false
            end

            it 'should be invalid case-insensitive abbreviation' do
                expect(TimezoneParser::Abbreviation.new('Pst').isValid?).to be false
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
                it 'should return correct offsets for ADT' do
                    expect(TimezoneParser::Abbreviation.new('ADT').setTime(DateTime.parse('1982-04-30T21:00:00+00:00')).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').setTime(DateTime.parse('1982-04-30T21:00:01+00:00')).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').setTime(DateTime.parse('1982-09-30T19:59:59+00:00')).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').setTime(DateTime.parse('1982-09-30T20:00:00+00:00')).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').setTime(DateTime.parse('1983-03-30T21:00:00+00:00'), DateTime.parse('1982-09-30T20:00:00+00:00')).getOffsets).to eq([-10800])
                end
            end

            context 'between specified time' do
                it 'should return correct offsets for SAST' do
                    expect(TimezoneParser::Abbreviation.new('SAST').setTime(DateTime.parse('1943-09-19T00:00:00+00:00'), DateTime.parse('1943-03-20T23:00:00+00:00')).getOffsets).to eq([7200])
                    expect(TimezoneParser::Abbreviation.new('SAST').setTime(DateTime.parse('1943-09-19T00:00:00+00:00'), DateTime.parse('1943-03-20T22:59:59+00:00')).getOffsets).to eq([7200, 10800])
                    expect(TimezoneParser::Abbreviation.new('SAST').setTime(DateTime.parse('1943-09-19T00:00:01+00:00'), DateTime.parse('1943-03-20T23:00:00+00:00')).getOffsets).to eq([7200, 10800])
                    expect(TimezoneParser::Abbreviation.new('SAST').setTime(DateTime.parse('1943-09-19T00:00:01+00:00'), DateTime.parse('1943-09-19T00:00:00+00:00')).getOffsets).to eq([7200, 10800])
                    expect(TimezoneParser::Abbreviation.new('SAST').setTime(DateTime.parse('1944-03-18T23:00:00+00:00'), DateTime.parse('1944-03-18T22:59:59+00:00')).getOffsets).to eq([7200, 10800])
                    expect(TimezoneParser::Abbreviation.new('SAST').setTime(DateTime.now, DateTime.parse('1944-03-18T23:00:00+00:00')).getOffsets).to eq([7200])
                end
            end

            context 'in specified region' do
                it 'should return correct offsets for ADT' do
                    expect(TimezoneParser::Abbreviation.new('ADT').set([]).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(['BM']).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').set(['GL']).getOffsets).to eq([-10800])
                    expect(TimezoneParser::Abbreviation.new('ADT').setTime(DateTime.parse('2007-10-01T00:00:00+00:00')).set(['BM', 'CA']).getOffsets).to eq([-10800])
                end
            end

            context 'with specified type' do
                it 'should return correct offsets for HAT' do
                    expect(TimezoneParser::Abbreviation.new('HAT').setTime(DateTime.parse('2014-02-05T10:00:00+00:00')).set(nil).getOffsets).to eq([-36000, -32400, -12600, -9000])
                    expect(TimezoneParser::Abbreviation.new('HAT').setTime(DateTime.parse('2014-04-05T10:00:00+00:00')).set(nil).getOffsets).to eq([-36000, -32400, -12600, -9000])
                    expect(TimezoneParser::Abbreviation.new('HAT').setTime(DateTime.parse('2014-02-05T10:00:00+00:00')).set(nil, :standard ).getOffsets).to eq([-36000, -12600])
                    expect(TimezoneParser::Abbreviation.new('HAT').setTime(DateTime.parse('2014-02-05T10:00:00+00:00')).set(nil, :daylight ).getOffsets).to eq([-32400, -9000])
                    expect(TimezoneParser::Abbreviation.new('HAT').setTime(DateTime.parse('2014-04-05T10:00:00+00:00')).set(nil, :standard ).getOffsets).to eq([-36000, -12600])
                    expect(TimezoneParser::Abbreviation.new('HAT').setTime(DateTime.parse('2014-04-05T10:00:00+00:00')).set(nil, :daylight ).getOffsets).to eq([-32400, -9000])
                end
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for KMT abbreviation' do
                expect(TimezoneParser::Abbreviation.new('KMT').setTime(DateTime.parse('1920-01-01T00:00:00+00:00')).getTimezones).to eq(['Europe/Kiev', 'Europe/Vilnius'])
            end

            context 'between specified time' do
                it 'should include correct timezones for EET' do
                    expect(TimezoneParser::Abbreviation.new('EET').setTime(DateTime.parse('1919-04-15T00:00:00+00:00'), DateTime.parse('1918-09-16T01:00:00+00:00')).getTimezones).to include('Asia/Beirut', 'Europe/Istanbul', 'Europe/Warsaw')
                    expect(TimezoneParser::Abbreviation.new('EET').setTime(DateTime.parse('1919-09-16T00:00:00+00:00'), DateTime.parse('1919-04-15T00:00:00+00:00')).getTimezones).to_not include('Europe/Warsaw')
                    expect(TimezoneParser::Abbreviation.new('EET').setTime(DateTime.parse('1985-04-19T21:00:00+00:00'), DateTime.parse('1978-10-14T21:00:00+00:00')).getTimezones).to_not include('Europe/Istanbul')
                end
            end

            context 'between times' do
                it 'should include correct timezones for AWT' do
                    abbr = TimezoneParser::Abbreviation.new('AWT')
                    abbr.FromTime = nil
                    abbr.ToTime = DateTime.parse('1990-01-01T00:00:00+00:00')
                    expect(abbr.getTimezones).to eq(['Antarctica/Casey', 'Australia/Perth'])

                    abbr.reset
                    abbr.FromTime = DateTime.parse('2014-01-01T00:00:00+00:00')
                    abbr.ToTime = nil
                    expect(abbr.getTimezones).to eq(['Antarctica/Casey', 'Australia/Perth'])

                    abbr.reset
                    expect(abbr.setTime(DateTime.parse('2015-01-01T00:00:00+00:00'), DateTime.parse('1985-01-01T00:00:00+00:00')).getTimezones).to eq(['Antarctica/Casey', 'Australia/Perth'])
                end
            end
        end

        describe '#getMetazones' do
            it 'should return all metazones for HAT abbreviation' do
                expect(TimezoneParser::Abbreviation.new('HAT').getMetazones).to eq(['Hawaii_Aleutian', 'Newfoundland'])
            end
        end

        describe '#getTypes' do
            it 'should return types for abbreviations' do
                expect(TimezoneParser::Abbreviation.new('EET').getTypes).to eq([:daylight, :standard])
                expect(TimezoneParser::Abbreviation.new('EEST').getTypes).to eq([:daylight])
            end
        end

        describe '.isValid?' do
            it 'should be valid abbreviation' do
                expect(TimezoneParser::Abbreviation::isValid?('WAST')).to be true
            end
        end

        describe '.couldBeValid?' do
            it 'should be valid abbreviation' do
                expect(TimezoneParser::Abbreviation.couldBeValid?('cet')).to be true
            end

            it 'should not be valid abbreviation' do
                expect(TimezoneParser::Abbreviation.couldBeValid?('WZE')).to be false
            end

            it 'should be valid case-insensitive abbreviation' do
                expect(TimezoneParser::Abbreviation.couldBeValid?('Pst')).to be true
            end
        end

        describe '.getOffsets' do
            it 'should return offsets for WAST abbreviation in NA region' do
                expect(TimezoneParser::Abbreviation::getOffsets('WAST', DateTime.now, nil, ['NA'])).to eq([3600])
            end
        end

        describe '.getTimezones' do
            it 'should return timezones for WAST abbreviation' do
                expect(TimezoneParser::Abbreviation::getTimezones('WAST', DateTime.parse('1994-07-28T01:14:40+00:00'), DateTime.parse('1988-07-28T03:26:56+00:00'), ['NA'])).to eq(['Africa/Windhoek'])
            end
        end

        describe '.getMetazones' do
            it 'should return metazones for HKT abbreviation' do
                expect(TimezoneParser::Abbreviation::getMetazones('HKT')).to eq(['Hong_Kong'])
            end
        end

    end
end
