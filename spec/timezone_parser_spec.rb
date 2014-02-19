# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe '.preload' do
        it 'should preload data files' do
            expect(TimezoneParser.preload).to be_true
        end
    end

    describe '.isValid?' do
        it 'should be valid timezone abbreviation' do
            expect(TimezoneParser.isValid?('HAP')).to be_true
        end

        it 'should be valid timezone name' do
            expect(TimezoneParser.isValid?('גיברלטר', ['he'])).to be_true
        end

        it 'should be valid Windows timezone name' do
            expect(TimezoneParser.isValid?('Θερινή ώρα Μαλαϊκής χερσονήσου', ['el-GR'])).to be_true
        end

        it 'should be valid Rails zone name' do
            expect(TimezoneParser.isValid?('ブエノスアイレス', ['ja'])).to be_true
        end

        it 'should not be valid' do
            expect(TimezoneParser.isValid?('blah')).to be_false
        end
    end

    describe '.getOffsets' do
        it 'should find offsets for timezone abbreviation' do
            expect(TimezoneParser.getOffsets('HAP', nil, nil, ['CA'])).to eq([-25200])
        end

        it 'should find offsets for timezone name' do
            expect(TimezoneParser.getOffsets('גיברלטר', nil, nil, ['GI'], ['he'])).to eq([3600, 7200])
        end

        it 'should find offsets for Windows timezone name' do
            expect(TimezoneParser.getOffsets('Θερινή ώρα Μαλαϊκής χερσονήσου', nil, nil, nil, ['el-GR'])).to eq([32400])
        end

        it 'should find offsets for Rails zone name' do
            expect(TimezoneParser.getOffsets('ブエノスアイレス', nil, nil, ['AR'], ['ja'])).to eq([-10800])
        end

        it 'should not find any offsets' do
            expect(TimezoneParser.getOffsets('blah')).to eq([])
        end
    end

    describe '.getTimezones' do
        it 'should find timezones for timezone abbreviation' do
            expect(TimezoneParser.getTimezones('HAP', nil, nil, ['CA'])).to eq(['America/Dawson', 'America/Vancouver', 'America/Whitehorse'])
        end

        it 'should find timezones for timezone name' do
            expect(TimezoneParser.getTimezones('גיברלטר', nil, nil, ['GI'], ['he'])).to eq(['Europe/Gibraltar'])
        end

        it 'should find timezones for Windows timezone name' do
            expect(TimezoneParser.getTimezones('Θερινή ώρα Μαλαϊκής χερσονήσου', nil, nil, nil, ['el-GR'])).to eq(['Asia/Brunei', 'Asia/Kuala_Lumpur', 'Asia/Kuching', 'Asia/Makassar', 'Asia/Manila', 'Asia/Singapore', 'Etc/GMT-8'])
        end

        it 'should find timezones for Rails zone name' do
            expect(TimezoneParser.getTimezones('ブエノスアイレス', nil, nil, ['AR'], ['ja'])).to eq(['America/Argentina/Buenos_Aires', 'America/Buenos_Aires'])
        end

        it 'should not find any timezones' do
            expect(TimezoneParser.getTimezones('blah')).to eq([])
        end
    end
end
