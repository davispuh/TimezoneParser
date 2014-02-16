# encoding: utf-8

module TimezoneParser
    class Timezone < ZoneInfo
        @@Locales = []
        @Timezone = nil

        attr_accessor :Locales
        attr_accessor :All
        def initialize(timezone)
            @Timezone = timezone
            @Data = Data.new
            @Valid = nil
            setTime
            set(@@Locales.dup, true)
        end

        def set(locales = nil, all = true)
            @Locales = locales unless locales.nil?
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
                        @Data.processEntry(entry, @ToTime, @FromTime)
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
                @Offsets = @Data.findOffsets(@ToTime, @FromTime, types).to_a
            else
                super
            end
            @Offsets
        end

        def self.isValid?(timezone, locales = nil)
            self.new(timezone).set(locales).isValid?
        end

        def self.getOffsets(timezone, toTime, fromTime, locales = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, all).getOffsets
        end

        def self.getTimezones(timezone, toTime, fromTime, locales = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, all).getTimezones
        end

        def self.getMetazones(timezone, toTime, fromTime, locales = nil, all = true)
            self.new(timezone).setTime(toTime, fromTime).set(locales, all).getMetazones
        end
    end
end
