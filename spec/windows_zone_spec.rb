# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe TimezoneParser::WindowsZone do
        describe '#new' do
            it 'should be an instance of a WindowsZone class' do
                expect(TimezoneParser::WindowsZone.new('Azerbaijan Summer Time')).to be_an_instance_of TimezoneParser::WindowsZone
            end
        end

        describe '#isValid?' do
            it 'should be valid Windows zone' do
                expect(TimezoneParser::WindowsZone.new('Azerbaijan Summer Time').isValid?).to be_true
            end

            it 'should not be valid Windows zone' do
                expect(TimezoneParser::WindowsZone.new('NotExisistinge').isValid?).to be_false
            end

        end

        describe '#getOffsets' do
            it 'should return all offsets for "Severoázijský čas (normálny)"' do
                expect(TimezoneParser::WindowsZone.new('Severoázijský čas (normálny)').getOffsets).to eq([28800])
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for "كوريا - التوقيت الرسمي"' do
                expect(TimezoneParser::WindowsZone.new('كوريا - التوقيت الرسمي').getTimezones).to eq(['Asia/Pyongyang', 'Asia/Seoul'])
            end

            it 'it should not find "GMT Daylight Time" in "en-GB" locale' do
                expect(TimezoneParser::WindowsZone.new('GMT Daylight Time').set(['en-GB']).getTimezones).to be_empty
            end

            it 'should look for timezone in "SR" region and with "sl-SI" locale' do
                expect(TimezoneParser::WindowsZone.new('Južnoameriški vzh. stand. čas').set(['sl-SI'], ['SR']).getTimezones).to eq(['America/Paramaribo'])
            end

        end

        describe '#getZone' do
            it 'should return zone name' do
                expect(TimezoneParser::WindowsZone.new('ora legale Medioatlantico').getZone).to eq('Mid-Atlantic Standard Time')
            end
        end
    end
end
