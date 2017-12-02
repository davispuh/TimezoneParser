# encoding: utf-8
require_relative 'timezone_parser/version'
require_relative 'timezone_parser/data'
require_relative 'timezone_parser/zone_info'
require_relative 'timezone_parser/abbreviation'
require_relative 'timezone_parser/timezone'
require_relative 'timezone_parser/windows_zone'
require_relative 'timezone_parser/rails_zone'

# TimezoneParser module
module TimezoneParser

    protected
    @@Modules = []
    @@Regions = []
    @@Locales = []

    public

    # Modules which to use by default when no modules are specified
    AllModules = [:Abbreviations, :Timezones, :WindowsZones, :RailsZones].freeze

    # Modules which will be used for TimezoneParser methods if not specified there
    # @return [Array<Symbol>] list containing symbol names for modules to use
    # @see AllModules
    def self.Modules
        @@Modules
    end

    # Regions which will be used for TimezoneParser methods if not specified there
    #
    # Each region is either ISO 3166-1 alpha-2 code or CLDR territory (UN M.49)
    # @return [Array<String>] list containing region identifiers
    # @see http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    # @see http://www.unicode.org/cldr/charts/latest/supplemental/territory_containment_un_m_49.html
    def self.Regions
        @@Regions
    end

    # Locales which will be used for TimezoneParser methods if not specified there
    #
    # Each locale is language identifier based on IETF BCP 47. Usually is either language identifier or language and country/region identifier
    # @return [Array<String>] list containing locale identifiers
    # @see http://en.wikipedia.org/wiki/IETF_language_tag
    # @see http://unicode.org/reports/tr35/#Unicode_Language_and_Locale_Identifiers
    # @see http://www.unicode.org/cldr/charts/latest/supplemental/language_territory_information.html
    # @see http://msdn.microsoft.com/en-us/library/dd318693.aspx
    def self.Locales
        @@Locales
    end

    # Check if given Timezone name is a valid timezone
    # @param name [String] either Timezone name or abbreviation
    # @param locales [Array<String>] check only for these locales
    # @param modules [Array<Symbol>] list of modules from which to check
    # @return [Boolean] whether Timezone is valid
    # @see Locales
    # @see Modules
    # @see AllModules
    # @see Abbreviation.isValid?
    # @see Timezone.isValid?
    # @see WindowsZone.isValid?
    # @see RailsZone.isValid?
    def self.isValid?(name, locales = @@Locales, modules = @@Modules)
        valid = false
        modules = AllModules if modules.nil? or modules.empty?
        valid = Abbreviation::isValid?(name) if modules.include?(:Abbreviations)
        return valid if valid

        valid = Timezone::isValid?(name, locales) if modules.include?(:Timezones)
        return valid if valid

        valid = WindowsZone::isValid?(name, locales) if modules.include?(:WindowsZones)
        return valid if valid

        valid = RailsZone::isValid?(name, locales) if modules.include?(:RailsZones)
        valid
    end

    # Get UTC offsets in seconds for given Timezone name
    # @param name [String] either Timezone name or abbreviation
    # @param toTime [DateTime] look for offsets which came into effect before this date, exclusive
    # @param fromTime [DateTime] look for offsets which came into effect at this date, inclusive
    # @param regions [Array<String>] look for offsets only for these regions
    # @param locales [Array<String>] search Timezone name only for these locales
    # @param type [Symbol] specify whether offset should be :standard time or :daylight
    # @param all [Boolean] specify whether should search for all offsets or return as soon as found any
    # @param modules [Array<Symbol>] list of modules from which to search
    # @return [Array<Fixnum>] list of timezone offsets in seconds
    # @see Regions
    # @see Locales
    # @see Modules
    # @see AllModules
    # @see Abbreviation.getOffsets
    # @see Timezone.getOffsets
    # @see WindowsZone.getOffsets
    # @see RailsZone.getOffsets
    def self.getOffsets(name, toTime = nil, fromTime = nil, regions = @@Regions, locales = @@Locales, type = nil, all = true, modules = @@Modules)
        offsets = SortedSet.new
        modules = AllModules if modules.nil? or modules.empty?
        offsets += Abbreviation::getOffsets(name, toTime, fromTime, regions, type) if modules.include?(:Abbreviations)
        return offsets.to_a if not all and not offsets.empty?

        offsets += Timezone::getOffsets(name, toTime, fromTime, locales, regions) if modules.include?(:Timezones)
        return offsets.to_a if not all and not offsets.empty?

        offsets += WindowsZone::getOffsets(name, locales) if modules.include?(:WindowsZones)
        return offsets.to_a if not all and not offsets.empty?

        offsets += RailsZone::getOffsets(name, toTime, fromTime, locales) if modules.include?(:RailsZones)
        offsets.to_a
    end

    # Get Timezone identifiers for given Timezone name
    # @param name [String] either Timezone name or abbreviation
    # @param toTime [DateTime] look for timezones which came into effect before this date, exclusive
    # @param fromTime [DateTime] look for timezones which came into effect at this date, inclusive
    # @param regions [Array<String>] look for timezones only for these regions
    # @param locales [Array<String>] search Timezone name only for these locales
    # @param type [Symbol] specify whether timezones should be :standard time or :daylight
    # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
    # @param modules [Array<Symbol>] list of modules from which to search
    # @return [Array<String>] list of timezone identifiers
    # @see Regions
    # @see Locales
    # @see Modules
    # @see AllModules
    # @see Abbreviation.getTimezones
    # @see Timezone.getTimezones
    # @see WindowsZone.getTimezones
    # @see RailsZone.getTimezones
    def self.getTimezones(name, toTime = nil, fromTime = nil, regions = @@Regions, locales = @@Locales, type = nil, all = true, modules = @@Modules)
        timezones = SortedSet.new
        modules = AllModules if modules.nil? or modules.empty?
        timezones += Abbreviation::getTimezones(name, toTime, fromTime, regions, type) if modules.include?(:Abbreviations)
        return timezones.to_a if not all and not timezones.empty?

        timezones += Timezone::getTimezones(name, toTime, fromTime, locales, regions) if modules.include?(:Timezones)
        return timezones.to_a if not all and not timezones.empty?

        timezones += WindowsZone::getTimezones(name, locales, regions) if modules.include?(:WindowsZones)
        return timezones.to_a if not all and not timezones.empty?

        timezones += RailsZone::getTimezones(name, locales) if modules.include?(:RailsZones)
        timezones.to_a
    end
end

