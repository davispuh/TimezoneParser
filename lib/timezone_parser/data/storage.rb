# encoding: utf-8
require 'yaml'
require 'date'
require 'insensitive_hash'

module TimezoneParser
    class Data
        class Storage
            @@Abbreviations = nil
            @@Timezones = nil
            @@TimezoneCountries = nil
            @@Metazones = nil
            @@WindowsZones = nil
            @@WindowsTimezones = nil
            @@WindowsOffsets = nil
            @@RailsZones = nil
            @@RailsTranslated = nil
            def self.Abbreviations
                unless @@Abbreviations
                    @@Abbreviations = YAML.load_file(Data::DataDir + 'abbreviations.yml').insensitive
                    @@Abbreviations.each do |abbr, data|
                        data.each do |entry|
                            entry['From'] = DateTime.parse(entry['From']) if entry['From']
                            entry['To'] = DateTime.parse(entry['To']) if entry['To']
                        end
                    end
                end
                @@Abbreviations
            end

            def self.Timezones
                unless @@Timezones
                    @@Timezones = YAML.load_file(Data::DataDir + 'timezones.yml').insensitive
                end
                @@Timezones
            end

            def self.TimezoneCountries
                unless @@TimezoneCountries
                    @@TimezoneCountries = YAML.load_file(Data::DataDir + 'countries.yml').insensitive
                end
                @@TimezoneCountries
            end

            def self.Metazones
                unless @@Metazones
                    @@Metazones = YAML.load_file(Data::DataDir + 'metazones.yml').insensitive
                    @@Metazones.each do |zone, data|
                        data.each do |entry|
                            entry['From'] = DateTime.parse(entry['From']) if entry['From']
                            entry['To'] = DateTime.parse(entry['To']) if entry['To']
                        end
                    end
                end
                @@Metazones
            end

            def self.WindowsZones
                unless @@WindowsZones
                    @@WindowsZones = YAML.load_file(Data::DataDir + 'windows_zonenames.yml').insensitive
                end
                @@WindowsZones
            end

            def self.WindowsTimezones
                unless @@WindowsTimezones
                    @@WindowsTimezones = YAML.load_file(Data::DataDir + 'windows_timezones.yml').insensitive
                end
                @@WindowsTimezones
            end

            def self.WindowsOffsets
                unless @@WindowsOffsets
                    @@WindowsOffsets = YAML.load_file(Data::DataDir + 'windows_offsets.yml').insensitive
                end
                @@WindowsOffsets
            end

            def self.RailsZones
                unless @@RailsZones
                    @@RailsZones = YAML.load_file(Data::DataDir + 'rails.yml').insensitive
                end
                @@RailsZones
            end

            def self.RailsTranslated
                unless @@RailsTranslated
                    @@RailsTranslated = YAML.load_file(Data::DataDir + 'rails_i18n.yml').insensitive
                end
                @@RailsTranslated
            end

            def self.preload(modules)
                preloaded = false
                modules.each do |m|
                    case m
                    when :Abbreviations
                        self.Abbreviations
                        self.Metazones
                        preloaded = true
                    when :Timezones
                        self.Timezones
                        self.Metazones
                        preloaded = true
                    when :WindowsZones
                        self.WindowsZones
                        self.WindowsTimezones
                        self.WindowsOffsets
                        preloaded = true
                    when :RailsZones
                        self.RailsZones
                        self.RailsTranslated
                        preloaded = true
                    end
                end
                preloaded
            end

            def self.getTimezones(metazone, toTime, fromTime, regions = [])
                timezones = SortedSet.new
                if self.Metazones.has_key?(metazone)
                    entries = Data::loadEntries(self.Metazones[metazone], toTime, fromTime)
                    entries.each do |entry|
                        add = true
                        timezones += entry['Timezones'].select do |timezone|
                            if regions.empty?
                                true
                            else
                                timezoneRegions = self.TimezoneCountries[timezone]
                                timezoneRegions && !(regions & timezoneRegions).empty?
                            end
                        end
                    end
                end
                timezones
            end

            def self.getTimezones2(zone, regions = [])
                timezones = SortedSet.new
                if self.WindowsTimezones.has_key?(zone)
                    entries = self.WindowsTimezones[zone]
                    regions = entries.keys if regions.empty?
                    regions.each do |region|
                        next unless entries.has_key?(region)
                        timezones += entries[region]
                    end
                end
                timezones
            end

            def self.getOffsets(zone, types = [])
                offsets = SortedSet.new
                if self.WindowsOffsets.has_key?(zone)
                    data = self.WindowsOffsets[zone]
                    types = ['standard', 'daylight'] if types.empty?
                    types.each do |type|
                        next unless data.has_key?(type)
                        offsets << data[type]
                    end
                end
                offsets
            end
        end
    end
end
