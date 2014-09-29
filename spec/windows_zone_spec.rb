# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe TimezoneParser::WindowsZone do
        describe '#new' do
            it 'should not raise error' do
                expect { TimezoneParser::WindowsZone.new('Azerbaijan Summer Time') }.not_to raise_error
            end
        end

        describe '#isValid?' do
            it 'should be valid Windows zone' do
                expect(TimezoneParser::WindowsZone.new('Azerbaijan Summer Time').isValid?).to be true
            end

            it 'should not be valid Windows zone' do
                expect(TimezoneParser::WindowsZone.new('NotExisistinge').isValid?).to be false
            end

        end

        describe '#getOffsets' do
            it 'should return all offsets for "Severoázijský čas (normálny)"' do
                expect(TimezoneParser::WindowsZone.new('Severoázijský čas (normálny)').getOffsets).to eq([25200])
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for "كوريا - التوقيت الرسمي"' do
                expect(TimezoneParser::WindowsZone.new('كوريا - التوقيت الرسمي').getTimezones).to eq(['Asia/Pyongyang', 'Asia/Seoul'])
            end

            it 'it should not find "GMT Daylight Time" in "en-GB" locale' do
                expect(TimezoneParser::WindowsZone.new('GMT Daylight Time').set(['en-GB']).getTimezones).to be_empty
            end

            it 'should find timezones for "SR" region and in "sl-SI" locale' do
                expect(TimezoneParser::WindowsZone.new('Južnoameriški vzh. stand. čas').set(['sl-SI'], ['SR']).getTimezones).to eq(['America/Paramaribo'])
            end

        end

        describe '#getZone' do
            it 'should return zone name' do
                expect(TimezoneParser::WindowsZone.new('ora legale Medioatlantico').getZone).to eq('Mid-Atlantic Standard Time')
            end
        end

        describe '.isValid?' do
            it 'should be valid Windows zone' do
                expect(TimezoneParser::WindowsZone::isValid?('Ekaterinburg, oră standard', ['ro-RO'])).to be true
            end
        end

        describe '.getOffsets' do
            it 'should return all offsets for "Sør-Amerika (østlig sommertid)"' do
                expect(TimezoneParser::WindowsZone::getOffsets('Sør-Amerika (østlig sommertid)', ['lt-LT', 'nb-NO'])).to eq([-7200])
            end
        end

        describe '.getTimezones' do
            it 'should find timezones for "Južnoafriški poletni čas"' do
                expect(TimezoneParser::WindowsZone::getTimezones('Južnoafriški poletni čas', nil, ['MW', 'MZ'])).to eq(['Africa/Blantyre', 'Africa/Maputo'])
            end
        end

        describe '.getMetazones' do
            it 'should find metazones for "Južnoafriški poletni čas"' do
                expect(TimezoneParser::WindowsZone::getMetazones('Južnoafriški poletni čas')).to eq(['South Africa Standard Time'])
            end
        end

        describe '.getZone' do
            it 'should return zone name' do
                expect(TimezoneParser::WindowsZone::getZone('Južnoafriški poletni čas')).to eq('South Africa Standard Time')
            end
        end

    end
end
