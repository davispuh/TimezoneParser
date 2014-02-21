# encoding: utf-8

module TimezoneParser
    # Timezone
    class Timezone < ZoneInfo

        protected
        @@Locales = []
        @@Regions = []

        public
        # Locales which will be used for Timezone methods if not specified there
        #
        # Each locale is language identifier based on IETF BCP 47
        # @return [Array<String>] list containing locale identifiers
        # @see http://en.wikipedia.org/wiki/IETF_language_tag
        # @see http://unicode.org/reports/tr35/#Unicode_Language_and_Locale_Identifiers
        # @see http://www.unicode.org/cldr/charts/latest/supplemental/language_territory_information.html
        def self.Locales
            @@Locales
        end

        # Regions which will be used for Timezone methods if not specified there
        #
        # Each region is CLDR territory (UN M.49)
        # @return [Array<String>] list containing region identifiers
        # @see http://www.unicode.org/cldr/charts/latest/supplemental/territory_containment_un_m_49.html
        def self.Regions
            @@Regions
        end

        attr_accessor :Locales
        attr_accessor :Regions
        attr_accessor :All

        # Timezone instance
        # @param timezone [String] Timezone name
        def initialize(timezone)
            @Timezone = timezone
            @Data = Data.new
            @Valid = nil
            setTime
            set(@@Locales.dup, @@Regions.dup, true)
        end

        # Set locales, regions and all
        # @param locales [Array<String>] search only in these locales
        # @param regions [Array<String>] filter for these regions
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Timezone] self
        def set(locales = nil, regions = nil, all = true)
            @Locales = locales unless locales.nil?
            @Regions = regions unless regions.nil?
            @All = all ? true : false
            self
        end

        # Check if timezone is valid
        # @return [Boolean] whether timezone is valid
        def isValid?
            if @Valid.nil?
                locales = @Locales
                locales = Data::Storage.Timezones.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.Timezones.has_key?(locale)
                    if Data::Storage.Timezones[locale].has_key?(@Timezone)
                        @Valid = true
                        return @Valid
                    end
                end
            end
            @Valid = false
        end

        # Abbreviation data
        # @return [Data] data
        def getData
            unless @Loaded
                @Loaded = true
                @Valid = false
                locales = @Locales
                locales = Data::Storage.Timezones.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.Timezones.has_key?(locale)
                    entry = Data::Storage.Timezones[locale][@Timezone]
                    if entry
                        @Data.processEntry(entry, @ToTime, @FromTime, @Regions)
                        @Valid = true
                        return @Data unless @All
                    end
                end
            end
            @Data
        end

        # Get UTC offsets in seconds
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        def getOffsets
            if not @Offsets and not getTimezones.empty?
                types = [@Type] if @Type
                @Offsets = @Data.findOffsets(@ToTime, @FromTime, @Regions, types).to_a
            else
                super
            end
            @Offsets
        end

        # Check if given Timezone name is a valid timezone
        # @param timezone [String] Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @return [Boolean] whether Timezone is valid
        # @see Locales
        def self.isValid?(timezone, locales = nil)
            self.new(timezone).set(locales).isValid?
        end

        # Get UTC offsets in seconds for given Timezone name
        # @param timezone [String] Timezone name
        # @param toTime [DateTime] look for offsets which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for offsets which came into effect at this date, inclusive
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for offsets only for these regions
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Locales
        # @see Regions
        def self.getOffsets(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions, all).getOffsets
        end

        # Get Timezone identifiers for given Timezone name
        # @param timezone [String] Timezone name
        # @param toTime [DateTime] look for timezones which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for timezones which came into effect at this date, inclusive
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for timezones only for these regions
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<String>] list of timezone identifiers
        # @see Locales
        # @see Regions
        def self.getTimezones(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions, all).getTimezones
        end

        # Get Metazone identifiers for given Timezone name
        # @param timezone [String] Timezone name
        # @param toTime [DateTime] look for timezones which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for timezones which came into effect at this date, inclusive
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for timezones only for these regions
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<String>] list of metazone identifiers
        # @see Locales
        # @see Regions
        def self.getMetazones(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions, all).getMetazones
        end
    end
end
