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
            set(DateTime.now, @@Regions.dup, nil)
        end

        def set(time, regions = nil, type = nil)
            @Time = time
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
                        @Data.processEntry(data.first, @Time)
                        return @Data
                    end
                    entries = Data.filterData(data, @Time, @Type, @Regions)
                    entries.each do |entry|
                        @Data.processEntry(entry, @Time)
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
                    @Offsets = @Data.findOffsets(@Time, @Regions, types).to_a
                end
            end
            @Offsets
        end

        def self.isValid?(abbreviation)
            Data::Storage.Abbreviations.has_key?(abbreviation)
        end

        def self.getOffsets(abbreviation, time = DateTime.now, regions = nil, type = nil)
            self.new(abbreviation).set(time, regions, type).getOffsets
        end

        def self.getTimezones(abbreviation, time = DateTime.now, regions = nil, type = nil)
            self.new(abbreviation).set(time, regions, type).getTimezones
        end

        def self.getMetazones(abbreviation, time = DateTime.now, regions = nil, type = nil)
            self.new(abbreviation).set(time, regions, type).getMetazones
        end
    end
end
