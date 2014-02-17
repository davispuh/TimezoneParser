# encoding: utf-8

module TimezoneParser
    class Abbreviation < ZoneInfo
        @@Regions = []
        @Abbreviation = nil

        attr_accessor :Regions
        attr_accessor :Type
        def initialize(abbreviation)
            @Abbreviation = abbreviation
            @Data = Data.new
            setTime
            set(@@Regions.dup, nil)
        end

        def set(regions = nil, type = nil)
            @Regions = regions unless regions.nil?
            @Type = type.to_s if type
            self
        end

        def isValid?
            Data::Storage.Abbreviations.has_key?(@Abbreviation)
        end

        def getData
            unless @Loaded
                @Loaded = true
                if isValid?
                    data = Data::Storage.Abbreviations[@Abbreviation]
                    if data.count == 1
                        @Data.processEntry(data.first, @ToTime, @FromTime)
                        return @Data
                    end
                    entries = Data.filterData(data, @ToTime, @FromTime, @Type, @Regions)
                    entries.each do |entry|
                        @Data.processEntry(entry, @ToTime, @FromTime)
                    end
                    return @Data
                end
            end
            @Data
        end

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

        def self.isValid?(abbreviation)
            Data::Storage.Abbreviations.has_key?(abbreviation)
        end

        def self.getOffsets(abbreviation, toTime = nil, fromTime = nil, regions = nil, type = nil)
            self.new(abbreviation).setTime(toTime, fromTime).set(regions, type).getOffsets
        end

        def self.getTimezones(abbreviation, toTime = nil, fromTime = nil, regions = nil, type = nil)
            self.new(abbreviation).setTime(toTime, fromTime).set(regions, type).getTimezones
        end

        def self.getMetazones(abbreviation)
            self.new(abbreviation).getMetazones
        end
    end
end
