# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe TimezoneParser::RailsZone do
        describe '#new' do
            it 'should not raise error' do
                expect { TimezoneParser::RailsZone.new('노보시비르스크') }.not_to raise_error
            end
        end

        describe '#isValid?' do
            it 'should be valid Rails zone' do
                expect(TimezoneParser::RailsZone.new('노보시비르스크').isValid?).to be true
            end

            it 'should not be valid Rails zone in "ru" locale' do
                expect(TimezoneParser::RailsZone.new('노보시비르스크').set(['ru']).isValid?).to be false
            end

            it 'should not be valid Rails zone' do
                expect(TimezoneParser::RailsZone.new('NotExisistinge').isValid?).to be false
            end
        end

        describe '#getOffsets' do
            it 'should return all offsets for "Grönland"' do
                expect(TimezoneParser::RailsZone.new('Grönland').getOffsets).to eq([-10800, -7200])
            end

            it 'should return all offsets for "Ньюфаундленд" in CA region' do
                expect(TimezoneParser::RailsZone.new('Ньюфаундленд').set( nil, ['CA']).getOffsets).to eq([-12600, -9000])
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for "Centro-Oeste de África"' do
                expect(TimezoneParser::RailsZone.new('Centro-Oeste de África').getTimezones).to eq(['Africa/Algiers'])
            end

            it 'it should not find "Hawaii" in "es" locale' do
                expect(TimezoneParser::RailsZone.new('Hawaii').set(['es']).getTimezones).to be_empty
            end

            it 'should find timezones for "pt" locale' do
                expect(TimezoneParser::RailsZone.new('Hora do Pacífico (EUA e Canadá)').set(['pt']).getTimezones).to eq(['America/Los_Angeles'])
            end

        end

        describe '#getZone' do
            it 'should return zone name' do
                expect(TimezoneParser::RailsZone.new('Североамериканское атлантическое время').getZone).to eq('Atlantic Time (Canada)')
            end
        end

        describe '.isValid?' do
            it 'should be valid Rails zone' do
                expect(TimezoneParser::RailsZone::isValid?('La Paz', ['en'])).to be true
            end
        end

        describe '.getOffsets' do
            it 'should return all offsets for "Nuku\'alofa"' do
                expect(TimezoneParser::RailsZone::getOffsets('Nuku\'alofa', DateTime.parse('2018-01-01T00:00:00+00:00'), nil, ['en', 'ru'])).to eq([46800, 50400])
                expect(TimezoneParser::RailsZone::getOffsets('Nuku\'alofa', DateTime.parse('2017-01-15T02:59:59+14:00'), DateTime.parse('2016-11-06T02:00:00+13:00'), ['en', 'ru'])).to eq([50400])
                expect(TimezoneParser::RailsZone::getOffsets('Nuku\'alofa', DateTime.parse('2018-07-01T00:00:00+00:00'), DateTime.parse('2017-01-15T03:00:00+14:00'), ['en', 'ru'])).to eq([46800])
            end
        end

        describe '.getTimezones' do
            it 'should find timezones' do
                expect(TimezoneParser::RailsZone::getTimezones('치와와', [])).to eq(['America/Chihuahua'])
            end
        end

        describe '.getMetazones' do
            it 'should raise error' do
                expect { TimezoneParser::RailsZone::getMetazones('치와와') }.to raise_error(StandardError)
            end
        end

        describe '.getZone' do
            it 'should return zone name' do
                expect(TimezoneParser::RailsZone::getZone('치와와')).to eq('Chihuahua')
            end
        end

    end
end
