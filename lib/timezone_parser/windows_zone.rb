# encoding: utf-8

module TimezoneParser
    class WindowsData < Data
        attr_reader :WindowsZone
        @WindowsZone = nil
        def processEntry(entry, region)
            @Types += entry['Types'] if entry['Types']
            if entry.has_key?('Metazones')
                entry['Metazones'].each do |zone|
                    @WindowsZone = zone
                    @Metazones << zone
                    @Timezones += Storage.getTimezones2(zone, region)
                    @Offsets += Storage.getOffsets(zone, entry['Types'])
                end
            end
            self
        end
    end

    class WindowsZone < ZoneInfo
        @@Locales = []
        @@Regions = []
        def self.Locales
            @@Locales
        end

        def self.Regions
            @@Regions
        end

        attr_accessor :Locales
        attr_accessor :Regions
        attr_accessor :All

        def initialize(name)
            @Name = name
            @Data = WindowsData.new
            @Valid = nil
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
                locales = Data::Storage.WindowsZones.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.WindowsZones.has_key?(locale)
                    @Valid = Data::Storage.WindowsZones[locale].has_key?(@Name)
                    return @Valid if @Valid
                end
            end
            @Valid = false
        end

        def getData
            unless @Loaded
                @Loaded = true
                @Valid = false
                locales = @Locales
                locales = Data::Storage.WindowsZones.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.WindowsZones.has_key?(locale)
                    entry = Data::Storage.WindowsZones[locale][@Name]
                    if entry
                        @Data.processEntry(entry, @Regions)
                        @Valid = true
                        return @Data unless @All
                    end
                end
            end
            @Data
        end

        def getZone
            getData.WindowsZone
        end

        def self.isValid?(name, locales = nil)
            self.new(name).set(locales).isValid?
        end

        def self.getOffsets(name, locales = nil, all = true)
            self.new(name).set(locales, nil, all).getOffsets
        end

        def self.getTimezones(name, locales = nil, regions = nil, all = true)
            self.new(name).set(locales, regions, all).getTimezones
        end

        def self.getMetazones(name, locales = nil, all = true)
            self.new(name).set(locales, nil, all).getMetazones
        end

        def self.getZone(name, locales = nil, all = true)
            self.new(name).set(locales, nil, all).getZone
        end
    end
end
