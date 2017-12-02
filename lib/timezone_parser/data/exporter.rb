require 'yaml'
require 'sqlite3'
require_relative 'tzinfo'
require_relative '../zone_info'

module TimezoneParser
    class Data
        # Timezone data Exporter class
        class Exporter
            Database = 'timezones.db'

            public

            def initialize(location)
                path = location + Database
                File.delete(path) if File.exist?(path)
                @Database = SQLite3::Database.new(path.to_s)
                @DataDir = Data::DataDir
            end

            def exportDatabase
                configure
                loadSchema
                loadLocales
                loadTerritories
                loadTimezones
                loadTimezoneTerritories
                loadMetazones
                loadTimezoneNames
                loadAbbreviations
                loadRailsTimezones
                loadRailsI18N
                loadWindowsZones
                loadWindowsZoneTimezones
                loadWindowsZoneNames
                finalize
            end

            private

            @Database = nil
            @LocaleIds = {}
            @TerritoryIds = {}
            @TimezoneIds = {}
            @MetazoneIds = {}
            @RailsTimezoneIds = {}
            @WindowsZoneIds = {}

            def configure
                @Database.application_id = 'TZPR'.unpack('l>').first.to_s
                @Database.user_version = TimezoneParser::VERSION.split('.').map(&:to_i).pack('CS>C').unpack('l>').first.to_s
                @Database.foreign_keys = true
                @Database.journal_mode = 'off'
                @Database.temp_store = 'memory'
                @Database.locking_mode = 'exclusive'
                @Database.synchronous = 'off'
            end

            def finalize
                @Database.execute('ANALYZE')
                @Database.execute('VACUUM')
            end

            def normalizeLocale(locale)
                locale = locale.gsub('_', '-')
                case locale
                when 'zh-CN'
                    locale = 'zh-Hans-CN'
                when 'zh-TW'
                    locale = 'zh-Hant-TW'
                when 'ha-Latn-NG'
                    locale = 'ha-NG'
                end
                locale
            end

            def getLocaleId(locale)
                @LocaleIds[normalizeLocale(locale)]
            end

            def loadSchema
                schema = File.read(@DataDir + 'schema.sql')
                @Database.execute_batch(schema)
            end

            def loadLocales
                @LocaleIds = {}
                locales = YAML.load_file(@DataDir + 'locales.yaml')
                locales.each do |locale|
                    locale = normalizeLocale(locale)
                    @Database.execute('INSERT INTO `Locales` (`Name`) VALUES (?)', locale)
                    @LocaleIds[locale] = @Database.last_insert_row_id
                end
                locales.each do |locale|
                    locale = normalizeLocale(locale)
                    if locale.include?('-')
                        parent = locale.split('-')[0..-2].join('-')
                        @Database.execute('UPDATE `Locales` SET `Parent` = ? WHERE `ID` = ?', getLocaleId(parent), getLocaleId(locale))
                    end
                end
            end

            def loadTerritories
                @TerritoryIds = {}
                territories = YAML.load_file(@DataDir + 'territories.yaml')
                (territories.to_a.flatten + ['ZZ']).sort.uniq.each do |territory|
                    @Database.execute('INSERT INTO `Territories` (`Territory`) VALUES (?)', territory)
                    @TerritoryIds[territory] = @Database.last_insert_row_id
                end
                territories.each do |parent, entries|
                    entries.each do |territory|
                        @Database.execute('INSERT INTO `TerritoryContainment` (`Parent`, `Territory`) VALUES (?, ?)', @TerritoryIds[parent], @TerritoryIds[territory])
                    end
                end
            end

            def loadTimezones
                @TimezoneIds = {}
                TimezoneParser::TZInfo.getTimezones.each do |timezone|
                    @Database.execute('INSERT INTO `Timezones` (`Name`) VALUES (?)', timezone)
                    @TimezoneIds[timezone] = @Database.last_insert_row_id
                end
            end

            def loadTimezoneTerritories
                YAML.load_file(@DataDir + 'countries.yaml').each do |timezone, countries|
                    countries.each do |country|
                        @Database.execute('INSERT INTO TimezoneTerritories (Timezone, Territory) VALUES (?, ?)', [@TimezoneIds[timezone], @TerritoryIds[country]])
                    end
                end
            end

            def loadMetazones
                @MetazoneIds = {}
                YAML.load_file(@DataDir + 'metazones.yaml').each do |metazone, entries|
                    @Database.execute('INSERT INTO `Metazones` (`Name`) VALUES (?)', [metazone])
                    @MetazoneIds[metazone] = @Database.last_insert_row_id
                    entries.each do |entry|
                        @Database.execute('INSERT INTO `MetazonePeriods` (`Metazone`, `From`, `To`) VALUES (?, ?, ?)', [@MetazoneIds[metazone], entry['From'], entry['To']])
                        period = @Database.last_insert_row_id
                        entry['Timezones'].each do |timezone|
                            @Database.execute('INSERT INTO `MetazonePeriod_Timezones` (`MetazonePeriod`, `Timezone`) VALUES (?, ?)', [period, @TimezoneIds[timezone]])
                        end
                    end
                end
            end

            def getTypes(data)
                types = nil
                if data['Types']
                    types = types.to_i | TimezoneParser::ZoneInfo::TIMEZONE_TYPE_STANDARD if data['Types'].include?('standard')
                    types = types.to_i | TimezoneParser::ZoneInfo::TIMEZONE_TYPE_DAYLIGHT if data['Types'].include?('daylight')
                end
                types
            end

            def loadTimezoneNames
                YAML.load_file(@DataDir + 'timezones.yaml').each do |locale, localeData|
                    localeData.each do |name, data|
                        @Database.execute('INSERT INTO TimezoneNames (`Locale`, `Name`, `NameLowercase`, Types) VALUES (?, ?, ?, ?)', [getLocaleId(locale), name, name.downcase, getTypes(data)])
                        nameId = @Database.last_insert_row_id
                        data['Timezones'].to_a.each do |timezone|
                            @Database.execute('INSERT INTO TimezoneName_Timezones (`Name`, `Timezone`) VALUES (?, ?)', [nameId, @TimezoneIds[timezone]])
                        end
                        data['Metazones'].to_a.each do |metazone|
                            @Database.execute('INSERT INTO TimezoneName_Metazones (`Name`, `Metazone`) VALUES (?, ?)', [nameId, @MetazoneIds[metazone]])
                        end
                    end
                end
            end

            def loadAbbreviations
                YAML.load_file(@DataDir + 'abbreviations.yaml').each do |abbreviation, entries|
                    @Database.execute('INSERT INTO `Abbreviations` (`Name`, `NameLowercase`) VALUES (?, ?)', [abbreviation, abbreviation.downcase])
                    abbreviationId = @Database.last_insert_row_id
                    entries.each do |entry|
                        @Database.execute('INSERT INTO `AbbreviationOffsets` (`Abbreviation`, `Offset`, `Types`, `From`, `To`) VALUES (?, ?, ?, ?, ?)', [abbreviationId, entry['Offset'], getTypes(entry), entry['From'], entry['To']])
                        offset = @Database.last_insert_row_id
                        entry['Timezones'].to_a.each do |timezone|
                            @Database.execute('INSERT INTO `AbbreviationOffset_Timezones` (`Offset`, `Timezone`) VALUES (?, ?)', [offset, @TimezoneIds[timezone]])
                        end
                        entry['Metazones'].to_a.each do |timezone|
                            @Database.execute('INSERT INTO `AbbreviationOffset_Metazones` (`Offset`, `Metazone`) VALUES (?, ?)', [offset, @MetazoneIds[timezone]])
                        end
                    end
                end
            end

            def loadRailsTimezones
                @RailsTimezoneIds = {}
                YAML.load_file(@DataDir + 'rails.yaml').each do |name, timezone|
                    @Database.execute('INSERT INTO `RailsTimezones` (`Name`, `Timezone`) VALUES (?, ?)', [name, @TimezoneIds[timezone]])
                    @RailsTimezoneIds[name] = @Database.last_insert_row_id
                    @Database.execute('INSERT INTO `RailsI18N` (`Locale`, `Name`, `NameLowercase`, `Zone`) VALUES (?, ?, ?, ?)', [getLocaleId('en'), name, name.downcase, @RailsTimezoneIds[name]])
                end
            end

            def loadRailsI18N
                YAML.load_file(@DataDir + 'rails_i18n.yaml').each do |locale, data|
                    data.each do |name, zone|
                        @Database.execute('INSERT INTO `RailsI18N` (`Locale`, `Name`, `NameLowercase`, `Zone`) VALUES (?, ?, ?, ?)', [getLocaleId(locale), name, name.downcase, @RailsTimezoneIds[zone]])
                    end
                end
            end

            def loadWindowsZones
                @WindowsZoneIds = {}
                YAML.load_file(@DataDir + 'windows_offsets.yaml').each do |zone, data|
                    @Database.execute('INSERT INTO `WindowsZones` (`Name`, `Standard`, `Daylight`) VALUES (?, ?, ?)', [zone, data['standard'], data['daylight']])
                    @WindowsZoneIds[zone] = @Database.last_insert_row_id
                end
            end

            def loadWindowsZoneTimezones
                YAML.load_file(@DataDir + 'windows_timezones.yaml').each do |zone, data|
                    unless @WindowsZoneIds.has_key?(zone)
                        puts "Warning! Need to update windows_offsets.yaml! No timezone offset found for '#{zone}'"
                        next
                    end
                    data.each do |territory, entries|
                        entries.each do |timezone|
                            @Database.execute('INSERT INTO `WindowsZone_Timezones` (`Zone`, `Territory`, `Timezone`) VALUES (?, ?, ?)', [@WindowsZoneIds[zone], @TerritoryIds[territory], @TimezoneIds[timezone]])
                        end
                    end
                end
            end

            def loadWindowsZoneNames
                YAML.load_file(@DataDir + 'windows_zonenames.yaml').each do |locale, localeData|
                    localeData.each do |name, data|
                        @Database.execute('INSERT INTO `WindowsZoneNames` (`Locale`, `Name`, `NameLowercase`, `Types`) VALUES (?, ?, ?, ?)', [getLocaleId(locale), name, name.downcase, getTypes(data)])
                        nameid = @Database.last_insert_row_id
                        data['Metazones'].to_a.each do |zone|
                            @Database.execute('INSERT INTO `WindowsZoneName_Zones` (`Name`, `Zone`) VALUES (?, ?)', [nameid, @WindowsZoneIds[zone]])
                        end
                    end
                end
            end

        end
    end
end
