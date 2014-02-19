# encoding: utf-8
require 'timezone_parser/version'
require 'timezone_parser/data'
require 'timezone_parser/zone_info'
require 'timezone_parser/abbreviation'
require 'timezone_parser/timezone'
require 'timezone_parser/windows_zone'
require 'timezone_parser/rails_zone'

module TimezoneParser

    @@Modules = []
    @@Regions = []
    @@Locales = []
    def self.Modules
        @@Modules
    end

    def self.Regions
        @@Regions
    end

    def self.Locales
        @@Locales
    end

    def self.getAllModules
        [:Abbreviations, :Timezones, :WindowsZones, :RailsZones]
    end

    def self.preload(modules = @@Modules)
        modules = getAllModules if modules.nil? or modules.empty?
        Data::Storage.preload(modules)
    end

    def self.isValid?(name, locales = @@Locales, modules = @@Modules)
        valid = false
        modules = getAllModules if modules.nil? or modules.empty?
        valid = Abbreviation::isValid?(name) if modules.include?(:Abbreviations)
        return valid if valid

        valid = Timezone::isValid?(name, locales) if modules.include?(:Timezones)
        return valid if valid

        valid = WindowsZone::isValid?(name, locales) if modules.include?(:WindowsZones)
        return valid if valid

        valid = RailsZone::isValid?(name, locales) if modules.include?(:RailsZones)
        valid
    end

    def self.getOffsets(name, toTime = nil, fromTime = nil, regions = @@Regions, locales = @@Locales, type = nil, all = true, modules = @@Modules)
        offsets = SortedSet.new
        modules = getAllModules if modules.nil? or modules.empty?
        offsets += Abbreviation::getOffsets(name, toTime, fromTime, regions, type) if modules.include?(:Abbreviations)
        return offsets.to_a if not all and not offsets.empty?

        offsets += Timezone::getOffsets(name, toTime, fromTime, locales, regions, all) if modules.include?(:Timezones)
        return offsets.to_a if not all and not offsets.empty?

        offsets += WindowsZone::getOffsets(name, locales, all) if modules.include?(:WindowsZones)
        return offsets.to_a if not all and not offsets.empty?

        offsets += RailsZone::getOffsets(name, toTime, fromTime, locales, all) if modules.include?(:RailsZones)
        offsets.to_a
    end

    def self.getTimezones(name, toTime = nil, fromTime = nil, regions = @@Regions, locales = @@Locales, type = nil, all = true, modules = @@Modules)
        timezones = SortedSet.new
        modules = getAllModules if modules.nil? or modules.empty?
        timezones += Abbreviation::getTimezones(name, toTime, fromTime, regions, type) if modules.include?(:Abbreviations)
        return timezones.to_a if not all and not timezones.empty?

        timezones += Timezone::getTimezones(name, toTime, fromTime, locales, regions, all) if modules.include?(:Timezones)
        return timezones.to_a if not all and not timezones.empty?

        timezones += WindowsZone::getTimezones(name, locales, regions, all) if modules.include?(:WindowsZones)
        return timezones.to_a if not all and not timezones.empty?

        timezones += RailsZone::getTimezones(name, locales, all) if modules.include?(:RailsZones)
        timezones.to_a
    end
end

