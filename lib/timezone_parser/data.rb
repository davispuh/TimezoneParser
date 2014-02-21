# encoding: utf-8
require 'pathname'
require 'set'
require 'tzinfo'
require 'timezone_parser/data/storage'

module TimezoneParser
    # Timezone data
    class Data
        # Library Root directory
        RootDir = Pathname.new(__FILE__).realpath.dirname.parent.parent
        # Path to Data directory
        DataDir = RootDir + 'data'
        # Path to Vendor directory
        VendorDir = RootDir + 'vendor'

        attr_reader :Offsets
        attr_reader :Timezones
        attr_reader :Types
        attr_reader :Metazones
        def initialize
            @Offsets = SortedSet.new
            @Timezones = SortedSet.new
            @Types = SortedSet.new
            @Metazones = SortedSet.new
        end

        def processEntry(entry, toTime, fromTime, regions = [])
            @Timezones += entry['Timezones'] if entry['Timezones']
            @Offsets << entry['Offset'] if entry['Offset']
            @Types += entry['Types'].map(&:to_sym) if entry['Types']
            if entry.has_key?('Metazones')
                entry['Metazones'].each do |zone|
                    @Metazones << zone
                    @Timezones += Storage.getTimezones(zone, toTime, fromTime, regions)
                end
            end
            self
        end

        def findOffsets(toTime, fromTime, regions = nil, types = nil)
            types = @Types.to_a unless types
            types = [:daylight, :standard] if types.empty?
            @Timezones.each do |timezone|
                if regions and not regions.empty?
                    timezoneRegions = Data::Storage.TimezoneCountries[timezone]
                    next if timezoneRegions and (timezoneRegions & regions).empty?
                end
                begin
                    tz = TZInfo::Timezone.get(timezone)
                rescue TZInfo::InvalidTimezoneIdentifier
                    tz = nil
                end
                next unless tz
                offsets = []
                ts = false
                tz.transitions_up_to(toTime, fromTime).each do |transition|
                    ts = true
                    self.class.addOffset(offsets, transition.offset, types)
                end
                self.class.addOffset(offsets, tz.period_for_utc(toTime - 0.001).offset, types) unless ts
                @Offsets += offsets
            end
            @Offsets
        end

        # Load data entries which match specified time
        # @param data [Array<Hash>] array of entries
        # @param toTime [DateTime] entries before this date, exclusive
        # @param fromTime [DateTime] entries after/at this date, inclusive
        # @return [Array<Hash>] resulting array containing filtered entries
        def self.loadEntries(data, toTime, fromTime, offsets = false)
            result = []
            data.each do |entry|
                result << entry if (entry['From'] && entry['To'] and toTime > entry['From'] and fromTime < entry['To']) or
                (entry['From'] && !entry['To'] and toTime > entry['From']) or
                (!entry['From'] && entry['To'] and fromTime < entry['To']) or
                (!entry['From'] && !entry['To'])
            end
            result.each do |entry|
                return result if not offsets or (offsets and entry['Offset'])
            end
            data.each_index do |i|
                entry = data[i]
                nextentry = offsets ? getNextEntry(data, i) : data[i+1]
                result << entry if ( entry['From'] && entry['To'] and toTime > entry['From'] and fromTime < entry['To'] ) or
                ( entry['To'] and ( (nextentry.nil? and fromTime >= entry['To']) or
                (nextentry and nextentry['From'] and fromTime >= entry['To'] and toTime <= nextentry['From']) or
                (!entry['From'] and fromTime < entry['To']) ) ) or
                ( entry['From'] and ( (i.zero? and toTime <= entry['From']) or (!entry['To'] and toTime > entry['From']) ) )
            end
            result
        end

        def self.filterData(data, toTime, fromTime, type, regions)
            entries = []
            data.each do |entry|
                next if type and entry['Types'] and not entry['Types'].include?(type)
                next if not regions.empty? and entry['Countries'] and (entry['Countries'] & regions).empty?
                entries << entry
            end
            loadEntries(entries, toTime, fromTime, true)
        end

        protected

        def self.getNextEntry(data, i)
            j = 1
            begin
                entry = data[i+j]
                j += 1
            end until entry.nil? or (entry and entry['Offset'])
            entry
        end

        def self.addOffset(offsets, offset, types)
            offsets << offset.utc_total_offset if (offset.dst? and types.include?(:daylight)) or (not offset.dst? and types.include?(:standard))
        end

    end
end
