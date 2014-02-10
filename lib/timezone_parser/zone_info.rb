# encoding: utf-8

module TimezoneParser
    class ZoneInfo
        @Data = nil
        @Loaded = false
        @Offsets = nil
        @Timezones = nil
        @Metazones = nil

        attr_accessor :Time
        def isValid?(name)
            false
        end

        def getData
            @Data
        end

        def getOffsets
            unless @Offsets
                @Offsets = getData.Offsets.to_a
            end
            @Offsets
        end

        def getTimezones
            unless @Timezones
                @Timezones = getData.Timezones.to_a
            end
            @Timezones
        end

        def getTypes
            unless @Types
                @Types = getData.Types.to_a
            end
            @Types
        end

        def getMetazones
            unless @Metazones
                @Metazones = getData.Metazones.to_a
            end
            @Metazones
        end

        def self.isValid?(name)
            false
        end

        def self.getOffsets(name)
            nil
        end

        def self.getTimezones(name)
            nil
        end

        def self.getMetazones(name)
            nil
        end
    end
end
