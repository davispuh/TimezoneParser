# encoding: utf-8

module TimezoneParser
    # Generic Timezone class
    class ZoneInfo
        protected
        @Data = nil
        @Loaded = false
        @Offsets = nil
        @Timezones = nil
        @Metazones = nil

        public
        attr_accessor :ToTime
        attr_accessor :FromTime
        # Set time range
        # @param toTime [DateTime] filter timezones before this date, exclusive
        # @param fromTime [DateTime] filter timezones at this date, inclusive
        # @return [ZoneInfo] self
        def setTime(toTime = nil, fromTime = nil)
            @ToTime = toTime
            @ToTime = DateTime.now unless @ToTime
            @FromTime = fromTime
            @FromTime = DateTime.new(@ToTime.year - 1) unless @FromTime
            self
        end

        # Get Timezone data
        def getData
            raise StandardError, '#getData must be implemented in subclass'
        end

        # Get UTC offsets in seconds
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        def getOffsets
            unless @Offsets
                @Offsets = getData.Offsets.to_a
            end
            @Offsets
        end

        # Get Timezone identifiers
        # @return [Array<String>] list of timezone identifiers
        def getTimezones
            unless @Timezones
                @Timezones = getData.Timezones.to_a
            end
            @Timezones
        end

        # Get types
        # @return [Symbol] types
        def getTypes
            unless @Types
                @Types = getData.Types.to_a
            end
            @Types
        end

        # Get Metazone identifiers
        # @return [Array<String>] list of Metazone identifiers
        def getMetazones
            unless @Metazones
                @Metazones = getData.Metazones.to_a
            end
            @Metazones
        end

    end
end
