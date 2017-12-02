# encoding: utf-8

module TimezoneParser
    # Generic Timezone class
    class ZoneInfo
        protected
        @Offsets = nil
        @Timezones = nil
        @Metazones = nil
        @TimezoneTypes = nil
        @ToTime = nil
        @FromTime = nil

        public

        TIMEZONE_TYPE_STANDARD = 0x01
        TIMEZONE_TYPE_DAYLIGHT = 0X02

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


        # Get UTC offsets in seconds
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        def getOffsets
            unless @Offsets
                @Offsets = self.getFilteredData(:Offsets)
            end
            @Offsets
        end

        # Get Timezone identifiers
        # @return [Array<String>] list of timezone identifiers
        def getTimezones
            unless @Timezones
                @Timezones = self.getFilteredData(:Timezones)
            end
            @Timezones
        end

        # Get Metazone identifiers
        # @return [Array<String>] list of Metazone identifiers
        def getMetazones
            unless @Metazones
                @Metazones = self.getFilteredData(:Metazones)
            end
            @Metazones
        end

        # Get Types
        # @return [Array<Symbol>] list of types
        def getTypes
            unless @TimezoneTypes
                @TimezoneTypes = self.getFilteredData(:Types)
            end
            @TimezoneTypes
        end

        # Reset cached result
        def reset
            @Offsets = nil
            @Timezones = nil
            @Metazones = nil
            @TimezoneTypes = nil
            @ToTime = nil
            @FromTime = nil
        end

        protected

        def getFilteredData(dataType)
            raise StandardError, '#getFilteredData must be implemented in subclass'
        end

        def self.findOffsets(timezones, toTime, fromTime, types = nil)
            toTime = Time.now unless toTime
            types = types.to_a unless types
            types = [:daylight, :standard] if types.empty?
            allOffsets = Set.new
            timezones.each do |timezone|
                begin
                    tz = TZInfo::Timezone.get(timezone)
                rescue TZInfo::InvalidTimezoneIdentifier
                    tz = nil
                end
                next unless tz
                offsets = []
                self.addOffset(offsets, tz.period_for_utc(fromTime).offset, types)
                tz.transitions_up_to(toTime, fromTime).each do |transition|
                    self.addOffset(offsets, transition.offset, types)
                end
                allOffsets += offsets
            end
            allOffsets.sort
        end

        def self.addOffset(offsets, offset, types)
            offsets << offset.utc_total_offset if (offset.dst? and types.include?(:daylight)) or (not offset.dst? and types.include?(:standard))
        end

        def self.convertTypes(rawTypes)
            types = Set.new
            rawTypes.each do |t|
                types << :standard unless (t.to_i & TIMEZONE_TYPE_STANDARD).zero?
                types << :daylight unless (t.to_i & TIMEZONE_TYPE_DAYLIGHT).zero?
            end
            types.sort
        end

        def self.findOffsetsFromTimezonesTypes(timezonesTypes, toTime, fromTime, types)
            timezones = Set.new
            timezoneTypes = Set.new
            timezonesTypes.each do |timezoneType|
                timezones << timezoneType[0]
                timezoneTypes << timezoneType[1]
            end

            timezoneTypes = self.convertTypes(timezoneTypes)

            if not types.nil? and not types.empty? and not timezoneTypes.empty?
               types &= timezoneTypes
            elsif not timezoneTypes.empty?
               types = timezoneTypes
            end

            self.findOffsets(timezones, toTime, fromTime, types).sort
        end

    end
end
