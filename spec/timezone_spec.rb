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
                expect(TimezoneParser::Timezone.new('Պարսկաստանի ամառային ժամանակ').getOffsets).to eq([16200])
            end
        end

        describe '#getTimezones' do
            it 'should return all timezones for "Bécs"' do
                expect(TimezoneParser::Timezone.new('Bécs').getTimezones).to eq(['Europe/Vienna'])
            end

            context 'timezones from specified locales' do
                it 'should find timezones for only "zh" locale' do
                    expect(TimezoneParser::Timezone.new('阿尤恩').set(['zh']).getTimezones).to eq(['Africa/El_Aaiun'])
                end

                it 'should find timezones for "en_Dsrt" locale' do
                    expect(TimezoneParser::Timezone.new('𐐁𐑍𐐿𐐲𐑉𐐮𐐾').set(['en_Dsrt']).getTimezones).to eq(['America/Anchorage'])
                end

                it 'it should not find "China Summer Time" in "en" locale' do
                    expect(TimezoneParser::Timezone.new('China Summer Time').set(['en']).getTimezones).to be_empty
                end
            end

            context 'timezones from specified regions' do
                it 'should find  timezones in only "LT" region' do
                    expect(TimezoneParser::Timezone.new('ເວລາເອີຣົບຕາເວັນອອກ').set(nil, ['LT']).getTimezones).to eq(['Europe/Vilnius'])
                end

                it 'should find timezones in only "GR", "FI" and "BG" regions' do
                    expect(TimezoneParser::Timezone.new('ເວລາເອີຣົບຕາເວັນອອກ').set(nil, ['GR', 'FI', 'BG']).getTimezones).to eq(['Europe/Athens', 'Europe/Helsinki', 'Europe/Sofia'])
                end
            end

            context 'timezones from specified time range' do
                it 'should find timezones between specified time range' do
                    expect(TimezoneParser::Timezone.new('Maskvos laikas').setTime(DateTime.parse('1992-01-19T00:00:00+00:00'), DateTime.parse('1991-03-30T23:00:00+00:00')).getTimezones).to eq(['Europe/Kaliningrad', 'Europe/Minsk', 'Europe/Moscow', 'Europe/Vilnius', 'Europe/Zaporozhye'])
                    expect(TimezoneParser::Timezone.new('Maskvos laikas').setTime(DateTime.parse('2010-03-27T22:00:00+00:00'), DateTime.parse('1992-01-19T00:00:00+00:00')).getTimezones).to eq(['Europe/Moscow', 'Europe/Simferopol'])
                end
            end
        end

        describe '#getMetazones' do
            it 'should return all metazones for "Nord-Marianene-tid"' do
                expect(TimezoneParser::Timezone.new('Nord-Marianene-tid').getMetazones).to eq(['North_Mariana'])
            end
        end

        describe '#getTypes' do
            it 'should return types for "Nord-Marianene-tid"' do
                expect(TimezoneParser::Timezone.new('Nord-Marianene-tid').getTypes).to eq([:standard])
            end
        end

        describe '.isValid?' do
            it 'should be valid timezone' do
                expect(TimezoneParser::Timezone::isValid?('பெட்ரோபவ்லோவ்ஸ்க் கம்சட்ஸ்கி நேரம்')).to be_true
            end
        end

        describe '.getOffsets' do
            it 'should find offsets for "सामोआ प्रमाण वेळ" zone and in "UM" region' do
                expect(TimezoneParser::Timezone::getOffsets('सामोआ प्रमाण वेळ', nil, nil, nil, ['UM'])).to eq([-39600])
            end
        end

        describe '.getTimezones' do
            it 'should return all timezones for "Grinwish gaƒoƒome"' do
                expect(TimezoneParser::Timezone::getTimezones('Grinwish gaƒoƒome', nil, nil, ['dz', 'ee'], ['IM'])).to eq(['Europe/Isle_of_Man'])
            end
        end

        describe '.getMetazones' do
            it 'should return all metazones for "ནུབ་ཕྱོགས་གིརིན་ལེནཌ་ཆུ་ཚོད"' do
                expect(TimezoneParser::Timezone::getMetazones('ནུབ་ཕྱོགས་གིརིན་ལེནཌ་ཆུ་ཚོད')).to eq(['Greenland_Western'])
            end
        end

    end
end
