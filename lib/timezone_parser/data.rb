# encoding: utf-8
require 'pathname'
require 'set'
require 'tzinfo'
require 'timezone_parser/data/storage'

module TimezoneParser
    class Data
        RootDir = Pathname.new(__FILE__).realpath.dirname.parent.parent
        DataDir = RootDir + 'data'
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

        def processEntry(entry, time)
            @Timezones += entry['Timezones'] if entry['Timezones']
            @Offsets << entry['Offset'] if entry['Offset']
            @Types += entry['Types'] if entry['Types']
            if entry.has_key?('Metazones')
                entry['Metazones'].each do |zone|
                    @Metazones << zone
                    @Timezones += Storage.getTimezones(zone, time)
                end
            end
            self
        end

        def sort!
            @Timezones = Set.new(@Timezones.sort)
            @Offsets = Set.new(@Offsets.sort)
            @Types = Set.new(@Types.sort)
            @Metazones = Set.new(@Metazones.sort)
            self
        end

        def findOffsets(time, regions = nil, types = nil)
            types = @Types.to_a unless types
            types = types.delete_if { |type| type != 'daylight' and type != 'standard' }
            types = ['daylight', 'standard'] if types.empty?
            @Timezones.each do |timezone|
                if regions and not regions.empty?
                    timezoneRegions = Data::Storage.TimezoneCountries[timezone]
                    if timezoneRegions and (timezoneRegions & regions).empty?
                        next
                    end
                end
                begin
                    tz = TZInfo::Timezone.get(timezone)
                rescue TZInfo::InvalidTimezoneIdentifier
                    tz = nil
                end
                next unless tz
                dst = nil
                tz.transitions_up_to(time).reverse.each do |transition|
                    offset = transition.offset
                    break if dst == offset.dst?
                    dst = offset.dst?
                    if offset.dst? and types.include?('daylight')
                        @Offsets << offset.utc_total_offset
                        types.delete('daylight')
                    else not offset.dst? and types.include?('standard')
                        @Offsets << offset.utc_total_offset
                        types.delete('standard')
                    end
                    break if types.empty?
                end
            end
            #@Offsets = Set.new(@Offsets.sort)
            @Offsets
        end

        # Load data entries which match specified time
        # @param data [Array<Hash>] array of entries
        # @return [Array<Hash>] resulting array containing filtered entries
        def self.loadEntries(data, time)
            result = []
            data.each do |entry|
                result << entry if (entry['From'] && entry['To'] and time >= entry['From'] and time < entry['To']) or
                (entry['From'] && !entry['To'] and time >= entry['From']) or
                (!entry['From'] && entry['To'] and time < entry['To']) or
                (!entry['From'] && !entry['To'])
            end
            result.each do |entry|
                return result if entry['Offsets'] and entry['Offsets'].count > 0
            end
            data.each_index do |i|
                entry = data[i]
                nextentry = data[i+1]
                result << entry if ( entry['From'] && entry['To'] and
                ((time >= entry['From'] and time < entry['To']) or
                (i.zero? and time < entry['From']) or (nextentry.nil? and time >= entry['To']) or
                (nextentry and nextentry['From'] and time < nextentry['From'] and time >= entry['To'])) ) or
                ( entry['From'] && !entry['To'] and (time >= entry['From'] or (i.zero? and time < entry['From'])) ) or
                ( !entry['From'] && entry['To'] and (time < entry['To'] or (nextentry.nil? and time >= entry['To'])) )
            end
            result
        end

        def self.filterData(data, time, type, regions)
            entries = []
            data.each do |entry|
                next if type and entry['Types'] and not entry['Types'].include?(type)
                next if not regions.empty? and entry['Countries'] and (entry['Countries'] & regions).empty?
                entries << entry
            end
            loadEntries(entries, time)
        end

    end
end
