# encoding: utf-8

module TimezoneParser
    class RailsData < Data
        attr_reader :RailsZone
        @RailsZone = nil
        def processEntry(data, rails)
            if rails
                @RailsZone = rails
                @Timezones << data
            else
                rails = Storage.RailsZones[data]
                if rails
                    @RailsZone = data
                    @Metazones << rails
                    @Timezones << rails
                end
            end
            self
        end
    end

    class RailsZone < ZoneInfo
        @@Locales = []
        @Name = nil

        attr_accessor :All
        def initialize(name)
            @Name = name
            @Data = RailsData.new
            @Valid = nil
            set(DateTime.now, @@Locales.dup, true)
        end

        def set(time, locales = nil, all = true)
            @Time = time
            @Locales = locales unless locales.nil?
            @All = all ? true : false
            self
        end

        def isValid?
            if @Valid.nil?
                @Valid = false
                @Valid = Data::Storage.RailsZones.has_key?(@Name) if (not @Locales) or (@Locales and @Locales.include?('en'))
                return @Valid if @Valid
                locales = @Locales
                locales = Data::Storage.RailsTranslated.keys if locales.empty?
                locales.each do |locale|
                    @Valid = Data::Storage.RailsTranslated[locale].has_key?(@Name)
                    return @Valid if @Valid
                end
            end
            @Valid = false
        end

        def getData
            unless @Loaded
                @Loaded = true
                @Valid = false
                @Valid = Data::Storage.RailsZones.has_key?(@Name) if (not @Locales) or (@Locales and @Locales.include?('en'))
                if @Valid
                    @Data.processEntry(Data::Storage.RailsZones[@Name], @Name)
                    return @Data unless @All
                end
                locales = @Locales
                locales = Data::Storage.RailsTranslated.keys if locales.empty?
                locales.each do |locale|
                    next unless Data::Storage.RailsTranslated.has_key?(locale)
                    entry = Data::Storage.RailsTranslated[locale][@Name]
                    if entry
                        @Data.processEntry(entry, false)
                        @Valid = true
                        return @Data unless @All
                    end
                end
            end
            @Data
        end

        def getOffsets
            if not @Offsets and not getTimezones.empty?
                @Offsets = @Data.findOffsets(@Time).to_a
            else
                super
            end
            @Offsets
        end

        def getZone
            getData.RailsZone
        end

        def self.isValid?(name, locales = nil)
            self.new(name).set(nil, locales).isValid?
        end

        def self.getOffsets(name, time = DateTime.now, locales = nil, all = true)
            self.new(name).set(time, locales, all).getOffsets
        end

        def self.getTimezones(name, locales = nil, all = true)
            self.new(name).set(nil, locales, all).getTimezones
        end

        def self.getMetazones(name, locales = nil, all = true)
            self.new(name).set(nil, locales, all).getMetazones
        end

        def self.getZone(name, locales = nil, all = true)
            self.new(name).set(nil, locales, all).getZone
        end
    end
end
