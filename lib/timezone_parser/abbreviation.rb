# encoding: utf-8

module TimezoneParser
    # Timezone abbreviation
    class Abbreviation < ZoneInfo
        protected
        @@Regions = []

        public
        # Regions which will be used for Abbreviation methods if not specified there
        #
        # Each region is either ISO 3166-1 alpha-2 code
        # @return [Array<String>] list containing region identifiers
        # @see http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
        def self.Regions
            @@Regions
        end

        attr_accessor :Regions
        attr_accessor :Type

        # Abbreviation instance
        # @param abbreviation [String] Timezone abbreviation
        def initialize(abbreviation)
            @Abbreviation = abbreviation
            @Data = Data.new
            setTime
            set(@@Regions.dup, nil)
        end

        # Set regions and type
        # @param regions [Array<String>] filter for these regions
        # @param type [Symbol] filter by type, :standard time or :daylight
        # @return [Abbreviation] self
        # @see Regions
        def set(regions = nil, type = nil)
            @Regions = regions unless regions.nil?
            @Type = type.to_sym if type
            self
        end

        # Check if abbreviation is valid
        # @return [Boolean] whether abbreviation is valid
        def isValid?
            Data::Storage.Abbreviations.has_key?(@Abbreviation)
        end

        # Abbreviation data
        # @return [Data] data
        def getData
            unless @Loaded
                @Loaded = true
                if isValid?
                    data = Data::Storage.Abbreviations[@Abbreviation]
                    if data.count == 1
                        @Data.processEntry(data.first, @ToTime, @FromTime, @Regions)
                        return @Data
                    end
                    entries = Data.filterData(data, @ToTime, @FromTime, @Type, @Regions)
                    entries.each do |entry|
                        @Data.processEntry(entry, @ToTime, @FromTime, @Regions)
                    end
                    return @Data
                end
            end
            @Data
        end

        # Get UTC offsets in seconds
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        def getOffsets
            unless @Offsets
                @Offsets = getData.Offsets.to_a
                if @Offsets.empty? and not getTimezones.empty?
                    types = nil
                    types = [@Type] if @Type
                    @Offsets = @Data.findOffsets(@ToTime, @FromTime, @Regions, types).to_a
                end
            end
            @Offsets
        end

        # Check if given Timezone abbreviation (case-sensitive) is a valid timezone
        # @param abbreviation [String] Timezone abbreviation
        # @return [Boolean] whether Timezone is valid
        def self.isValid?(abbreviation)
            Data::Storage.Abbreviations.has_key?(abbreviation)
        end

        # Check if given Timezone abbreviation (case-insensitive) could be a valid timezone
        # @param abbreviation [String] Timezone abbreviation to check for
        # @return [Boolean] whether Timezone is valid
        def self.couldBeValid?(abbreviation)
            Data::Storage.Abbreviations.each_key do |abbr|
              return true if abbr.casecmp(abbreviation).zero?
            end
            false
        end

        # Get UTC offsets in seconds for given Timezone abbreviation
        # @param abbreviation [String] Timezone abbreviation
        # @param toTime [DateTime] look for offsets which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for offsets which came into effect at this date, inclusive
        # @param regions [Array<String>] look for offsets only for these regions
        # @param type [Symbol] specify whether offset should be :standard time or :daylight
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Regions
        def self.getOffsets(abbreviation, toTime = nil, fromTime = nil, regions = nil, type = nil)
            self.new(abbreviation).setTime(toTime, fromTime).set(regions, type).getOffsets
        end

        # Get Timezone identifiers for given Timezone abbreviation
        # @param abbreviation [String] Timezone abbreviation
        # @param toTime [DateTime] look for timezones which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for timezones which came into effect at this date, inclusive
        # @param regions [Array<String>] look for timezones only for these regions
        # @param type [Symbol] specify whether timezones should be :standard time or :daylight
        # @return [Array<String>] list of timezone identifiers
        # @see Regions
        def self.getTimezones(abbreviation, toTime = nil, fromTime = nil, regions = nil, type = nil)
            self.new(abbreviation).setTime(toTime, fromTime).set(regions, type).getTimezones
        end

        # Get Metazone identifiers for given Timezone abbreviation
        # @param abbreviation [String] Timezone abbreviation
        def self.getMetazones(abbreviation)
            self.new(abbreviation).getMetazones
        end
    end
end
