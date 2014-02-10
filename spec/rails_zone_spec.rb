# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe TimezoneParser::RailsZone do
        describe '#new' do
            it 'should be an instance of a RailsZone class' do
                expect(TimezoneParser::RailsZone.new('노보시비르스크')).to be_an_instance_of TimezoneParser::RailsZone
            end
        end

        describe '#isValid?' do
            it 'should be valid Rails zone' do
                expect(TimezoneParser::RailsZone.new('노보시비르스크').isValid?).to be_true
            end

            it 'should not be valid Rails zone' do
                expect(TimezoneParser::RailsZone.new('NotExisistinge').isValid?).to be_false
            end
        end

        describe '#getOffsets' do
            it 'should return all offsets for "Grönland"' do
                expect(TimezoneParser::RailsZone.new('Grönland').getOffsets).to eq([-10800, -7200])
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for "Centro-Oeste de África"' do
                expect(TimezoneParser::RailsZone.new('Centro-Oeste de África').getTimezones).to eq(['Africa/Algiers'])
            end

            it 'it should not find "Hawaii" in "es" locale' do
                expect(TimezoneParser::RailsZone.new('Hawaii').set(nil, ['es']).getTimezones).to be_empty
            end

            it 'should look for timezone in "pt" locale' do
                expect(TimezoneParser::RailsZone.new('Hora do Pacífico (EUA e Canadá)').set(nil, ['pt']).getTimezones).to eq(['America/Los_Angeles'])
            end

        end

        describe '#getZone' do
            it 'should return zone name' do
                expect(TimezoneParser::RailsZone.new('Североамериканское атлантическое время').getZone).to eq('Atlantic Time (Canada)')
            end
        end
    end
end
