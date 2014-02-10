# encoding: utf-8
require 'spec_helper'

describe TimezoneParser do
    describe TimezoneParser::Timezone do
        describe '#new' do
            it 'should be an instance of a Timezone class' do
                expect(TimezoneParser::Timezone.new('Argentinische Normalzeit')).to be_an_instance_of TimezoneParser::Timezone
            end
        end

        describe '#isValid?' do
            it 'should be valid timezone' do
                expect(TimezoneParser::Timezone.new('Argentinische Normalzeit').isValid?).to be_true
            end

            it 'should not be valid timezone' do
                expect(TimezoneParser::Timezone.new('Random place').isValid?).to be_false
            end

            it 'should be valid case-insensitive' do
                expect(TimezoneParser::Timezone.new('büsingen').isValid?).to be_true
                pending('TODO: Unicode case insensitivity')
                expect(TimezoneParser::Timezone.new('bÜsingen').isValid?).to be_true
            end
        end

        describe '#getOffsets' do
            it 'should return all offsets for "Պարսկաստանի ամառային ժամանակ"' do
                expect(TimezoneParser::Timezone.new('Պարսկաստանի ամառային ժամանակ').getOffsets).to eq([12600, 16200])
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for "Bécs"' do
                expect(TimezoneParser::Timezone.new('Bécs').getTimezones).to eq(['Europe/Vienna'])
            end

            describe 'timezones from specific locales' do
                it 'should look for timezone in only "zh" locale' do
                    expect(TimezoneParser::Timezone.new('阿尤恩').set(DateTime.now, ['zh']).getTimezones).to eq(['Africa/El_Aaiun'])
                end

                it 'should find timezones for "en_Dsrt" locale' do
                    expect(TimezoneParser::Timezone.new('𐐁𐑍𐐿𐐲𐑉𐐮𐐾').set(DateTime.now, ['en_Dsrt']).getTimezones).to eq(['America/Anchorage'])
                end

                it 'it should not find "China Summer Time" in "en" locale' do
                    expect(TimezoneParser::Timezone.new('China Summer Time').set(DateTime.now, ['en']).getTimezones).to be_empty
                end
            end
        end

        describe '#getMetazones' do
            it 'should return all metazones for "Nord-Marianene-tid"' do
                expect(TimezoneParser::Timezone.new('Nord-Marianene-tid').getMetazones).to eq(['North_Mariana'])
            end
        end

    end
end
