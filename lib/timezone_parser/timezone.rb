# encoding: utf-8

module TimezoneParser
    class Timezone < ZoneInfo
        @@Locales = []
        @@Regions = []
        @Timezone = nil

        attr_accessor :Locales
        attr_accessor :Regions
        attr_accessor :All
        def initialize(timezone)
            @Timezone = timezone
            @Data = Data.new
            @Valid = nil
            setTime
            set(@@Locales.dup, @@Regions.dup, true)
        end

        def set(locales = nil, regions = nil, all = true)
            @Locales = locales unless locales.nil?
            @Regions = regions unless regions.nil?
            @All = all ? true : false
            self
        end

        def isValid?
            if @Valid.nil?
                locales = @Locales
                locales = Data::Storage.Timezones.keys if locales.empty?
                locales.each do |locale|
                    if Data::Storage.Timezones[locale].has_key?(@Timezone)
                        @Valid = true
                        return @Valid
                    end
                end
            end
            @Valid = false
        end

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

        def getOffsets
            if not @Offsets and not getTimezones.empty?
                types = [@Type] if @Type
                @Offsets = @Data.findOffsets(@ToTime, @FromTime, @Regions, types).to_a
            else
                super
            end
            @Offsets
        end

        def self.isValid?(timezone, locales = nil)
            self.new(timezone).set(locales).isValid?
        end

        def self.getOffsets(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions, all).getOffsets
        end

        def self.getTimezones(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions, all).getTimezones
        end

        def self.getMetazones(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions, all).getMetazones
        end
    end
end
