# encoding: utf-8

module TimezoneParser
    # Windows Timezone data
    class WindowsData < Data
        protected
        @WindowsZone = nil

        public
        attr_reader :WindowsZone
        def processEntry(entry, region)
            @Types += entry['Types'] if entry['Types']
            if entry.has_key?('Metazones')
                entry['Metazones'].each do |zone|
                    @WindowsZone = zone
                    @Metazones << zone
                    @Timezones += Storage.getTimezones2(zone, region)
                    @Offsets += Storage.getOffsets(zone, entry['Types'])
                end
            end
            self
        end
    end

    # Windows Timezone
    class WindowsZone < ZoneInfo
        protected
        @@Locales = []
        @@Regions = []

        public
        # Locales which will be used for WindowsZone methods if not specified there
        #
        # Each locale consists of language identifier and country/region identifier
        # @return [Array<String>] list containing locale identifiers
        # @see http://msdn.microsoft.com/en-us/library/dd318693.aspx
        def self.Locales
            @@Locales
        end

        # Regions which will be used for WindowsZone methods if not specified there
        #
        # Each region is either ISO 3166-1 alpha-2 code
        # @return [Array<String>] list containing region identifiers
        # @see http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
        def self.Regions
            @@Regions
        end

        attr_accessor :Locales
        attr_accessor :Regions
        attr_accessor :All

        # Windows Timezone instance
        # @param name [String] Windows Timezone name
        def initialize(name)
            @Name = name
            @Data = WindowsData.new
            @Valid = nil
            set(@@Locales.dup, @@Regions.dup, true)
        end

        # Set locales, regions and all
        # @param locales [Array<String>] search only in these locales
        # @param regions [Array<String>] filter for these regions
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [WindowsZone] self
        # @see Locales
        # @see Regions
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
                locales = Data::Storage.WindowsZones.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.WindowsZones.has_key?(locale)
                    @Valid = Data::Storage.WindowsZones[locale].has_key?(@Name)
                    return @Valid if @Valid
                end
            end
            @Valid = false
        end

        # Windows Timezone data
        # @return [WindowsData] data
        def getData
            unless @Loaded
                @Loaded = true
                @Valid = false
                locales = @Locales
                locales = Data::Storage.WindowsZones.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.WindowsZones.has_key?(locale)
                    entry = Data::Storage.WindowsZones[locale][@Name]
                    if entry
                        @Data.processEntry(entry, @Regions)
                        @Valid = true
                        return @Data unless @All
                    end
                end
            end
            @Data
        end

        # Windows Timezone identifier
        # @return [String] Timezone identifier
        def getZone
            getData.WindowsZone
        end

        # Check if given Windows Timezone name is a valid timezone
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @return [Boolean] whether Timezone is valid
        # @see Locales
        def self.isValid?(name, locales = nil)
            self.new(name).set(locales).isValid?
        end

        # Get UTC offsets in seconds for given Windows Timezone name
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Locales
        def self.getOffsets(name, locales = nil, all = true)
            self.new(name).set(locales, nil, all).getOffsets
        end

        # Get Timezone identifiers for given Windows Timezone name
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for timezones only for these regions
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<String>] list of timezone identifiers
        # @see Locales
        # @see Regions
        def self.getTimezones(name, locales = nil, regions = nil, all = true)
            self.new(name).set(locales, regions, all).getTimezones
        end

        # Get Metazone identifiers for given Windows Timezone name
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<String>] list of metazone identifiers
        # @see Locales
        def self.getMetazones(name, locales = nil, all = true)
            self.new(name).set(locales, nil, all).getMetazones
        end

        # Windows Timezone identifier
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [String] Timezone identifier
        def self.getZone(name, locales = nil, all = true)
            self.new(name).set(locales, nil, all).getZone
        end
    end
end
