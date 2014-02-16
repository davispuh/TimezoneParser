# encoding: utf-8
require 'timezone_parser/version'
require 'timezone_parser/data'
require 'timezone_parser/zone_info'
require 'timezone_parser/abbreviation'
require 'timezone_parser/timezone'
require 'timezone_parser/windows_zone'
require 'timezone_parser/rails_zone'

module TimezoneParser

    @@Modules = [:Abbreviations, :Timezones, :WindowsZones, :RailsZones]

    def self.preload(modules = @@Modules)
        Data::Storage.preload(modules)
    end

    def self.getOffsets(name, toTime = nil, fromTime = nil, regions = nil, locales = nil, type = nil, all = true, modules = @@Modules)
        offsets = SortedSet.new
        offsets += Abbreviation::getOffsets(name, toTime, fromTime, regions, type) if modules.include?(:Abbreviations)
        return offsets.to_a if all and not offsets.empty?

        offsets += Timezone::getOffsets(name, toTime, fromTime, locales, all) if modules.include?(:Timezones)
        return offsets.to_a if all and not offsets.empty?

        offsets += WindowsZone::getOffsets(name, locales, all) if modules.include?(:WindowsZones)
        return offsets.to_a if all and not offsets.empty?

        offsets += RailsZone::getOffsets(name, toTime, fromTime, locales, all) if modules.include?(:RailsZones)
        offsets.to_a
    end

    def self.getTimezones(name, toTime = nil, fromTime = nil, regions = nil, locales = nil, type = nil, all = true, modules = @@Modules)
        timezones = SortedSet.new
        timezones += Abbreviation::getTimezones(name, toTime, fromTime, regions, type) if modules.include?(:Abbreviations)
        return timezones.to_a if all and not timezones.empty?

        timezones += Timezone::getTimezones(name, toTime, fromTime, locales, all) if modules.include?(:Timezones)
        return timezones.to_a if all and not timezones.empty?

        timezones += WindowsZone::getTimezones(name, locales, regions, all) if modules.include?(:WindowsZones)
        return timezones.to_a if all and not timezones.empty?

        timezones += RailsZone::getTimezones(name, locales, all) if modules.include?(:RailsZones)
        timezones.to_a
    end
end

