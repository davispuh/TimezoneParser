# encoding: utf-8

module TimezoneParser
    # Rails zone data
    class RailsData < Data
        protected
        @RailsZone = nil

        public
        attr_reader :RailsZone
        def processEntry(data, rails)
            if rails
                @RailsZone = rails
                @Metazones << rails
                @Timezones << data
            else
                rails = Storage.RailsZones[data]
                if rails
                    @RailsZone = data
                    @Metazones << data
                    @Timezones << rails
                end
            end
            self
        end
    end

    # Rails zone
    class RailsZone < ZoneInfo
        protected
        @@Locales = []

        public
        # Locales which will be used for RailsZone methods if not specified there
        #
        # Each locale is language identifier based on IETF BCP 47 and ISO 639 code
        # @return [Array<String>] list containing locale identifiers
        # @see http://en.wikipedia.org/wiki/IETF_language_tag
        def self.Locales
            @@Locales
        end

        attr_accessor :All

        # Rails zone instance
        # @param name [String] Rails zone name
        def initialize(name)
            @Name = name
            @Data = RailsData.new
            @Valid = nil
            setTime
            set(@@Locales.dup, true)
        end

        # Set locales and all
        # @param locales [Array<String>] search only in these locales
        # @param all [Boolean] specify whether should search for all zones or return as soon as found any
        # @return [RailsZone] self
        # @see Locales
        def set(locales = nil, all = true)
            @Locales = locales unless locales.nil?
            @All = all ? true : false
            self
        end

        # Check if Rails zone is valid
        # @return [Boolean] whether Rails zone is valid
        def isValid?
            if @Valid.nil?
                @Valid = false
                @Valid = Data::Storage.RailsZones.has_key?(@Name) if (not @Locales) or (@Locales and @Locales.include?('en'))
                return @Valid if @Valid
                locales = @Locales
                locales = Data::Storage.RailsTranslated.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.RailsTranslated.has_key?(locale)
                    @Valid = Data::Storage.RailsTranslated[locale].has_key?(@Name)
                    return @Valid if @Valid
                end
            end
            @Valid = false
        end

        # Rails zone data
        # @return [RailsData] data
        def getData
            unless @Loaded
                @Loaded = true
                @Valid = false
                @Valid = Data::Storage.RailsZones.has_key?(@Name) if (not @Locales) or (@Locales and @Locales.include?('en'))
                if @Valid
                    @Data.processEntry(Data::Storage.RailsZones[@Name], @Name)
                    return @Data unless @All
                end
                locales = @Locales
                locales = Data::Storage.RailsTranslated.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.RailsTranslated.has_key?(locale)
                    entry = Data::Storage.RailsTranslated[locale][@Name]
                    if entry
                        @Data.processEntry(entry, false)
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
                @Offsets = @Data.findOffsets(@ToTime, @FromTime).to_a
            else
                super
            end
            @Offsets
        end

        # Rails zone identifier
        # @return [String] Rails zone identifier
        def getZone
            getData.RailsZone
        end

        # Check if given Rails zone name is a valid timezone
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @return [Boolean] whether Timezone is valid
        # @see Locales
        def self.isValid?(name, locales = nil)
            self.new(name).set(locales).isValid?
        end

        # Get UTC offsets in seconds for given Rails zone name
        # @param name [String] Rails zone name
        # @param toTime [DateTime] look for offsets which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for offsets which came into effect at this date, inclusive
        # @param locales [Array<String>] search zone name only for these locales
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Locales
        def self.getOffsets(name, toTime = nil, fromTime = nil, locales = nil, all = true)
            self.new(name).setTime(toTime, fromTime).set(locales, all).getOffsets
        end

        # Get Timezone identifiers for given Rails zone name
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<String>] list of timezone identifiers
        # @see Locales
        def self.getTimezones(name, locales = nil, all = true)
            self.new(name).set(locales, all).getTimezones
        end

        # Get Metazone identifiers for given Rails zone name
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [Array<String>] list of metazone identifiers
        # @see Locales
        # @see Regions
        def self.getMetazones(name, locales = nil, all = true)
            self.new(name).set(locales, all).getMetazones
        end

        # Rails zone identifier
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @param all [Boolean] specify whether should search for all timezones or return as soon as found any
        # @return [String] Timezone identifier
        def self.getZone(name, locales = nil, all = true)
            self.new(name).set(locales, all).getZone
        end
    end
end
