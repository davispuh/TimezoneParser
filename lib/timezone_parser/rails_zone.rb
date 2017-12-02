# encoding: utf-8

module TimezoneParser
    # Rails zone
    class RailsZone < ZoneInfo
        protected
        @@Locales = []
        @@Regions = []

        public
        # Locales which will be used for RailsZone methods if not specified there
        #
        # Each locale is language identifier based on IETF BCP 47 and ISO 639 code
        # @return [Array<String>] list containing locale identifiers
        # @see http://en.wikipedia.org/wiki/IETF_language_tag
        def self.Locales
            @@Locales
        end

        # Regions which will be used for WindowsZone methods if not specified there
        #
        # Each region is either ISO 3166-1 alpha-2 code
        # @return [Array<String>] list containing region identifiers
        # @see http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
        def self.Regions
            @@Regions
        end

        attr_accessor :Locales
        attr_accessor :Regions
        attr_accessor :Types

        # Rails zone instance
        # @param name [String] Rails zone name
        def initialize(name)
            @Name = name
            @Valid = nil
            setTime
            set(@@Locales.dup, @@Regions.dup)
        end

        # Set locales and regions
        # @param locales [Array<String>] search only in these locales
        # @param regions [Array<String>] filter for these regions
        # @return [WindowsZone] self
        # @see Locales
        # @see Regions
        def set(locales = nil, regions = nil, types = nil)
            @Locales = locales unless locales.nil?
            @Regions = regions unless regions.nil?
            @Types = types unless types.nil?
            self
        end

        # Check if Rails zone is valid
        # @return [Boolean] whether Rails zone is valid
        def isValid?
            if @Valid.nil?
                params = []
                joins = ''
                where = ''

                if not @Locales.empty?
                    joins += ' LEFT JOIN `Locales` AS L ON RI.Locale = L.ID'
                    where = 'L.Name COLLATE NOCASE IN (' + Array.new(@Locales.count, '?').join(',') + ') AND '
                    params += @Locales
                end

                sql = "SELECT 1 FROM `RailsI18N` RI #{joins} WHERE #{where}RI.`NameLowercase` = ? LIMIT 1"
                params << @Name.downcase

                @Valid = Data::Storage.getStatement(sql).execute(*params).count > 0
            end
            @Valid
        end

        # Rails zone identifier
        # @return [String] Rails zone identifier
        def getZone
            unless @Zone
                @Zone = self.getFilteredData(:Zone).first
            end
            @Zone
        end

        # Check if given Rails zone name is a valid timezone
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @return [Boolean] whether Timezone is valid
        # @see Locales
        def self.isValid?(name, locales = nil)
            self.new(name).set(locales).isValid?
        end

        # Get UTC offsets in seconds for given Rails zone name
        # @param name [String] Rails zone name
        # @param toTime [DateTime] look for offsets which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for offsets which came into effect at this date, inclusive
        # @param locales [Array<String>] search zone name only for these locales
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Locales
        def self.getOffsets(name, toTime = nil, fromTime = nil, locales = nil, types = nil)
            self.new(name).setTime(toTime, fromTime).set(locales, nil, types).getOffsets
        end

        # Get Timezone identifiers for given Rails zone name
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @return [Array<String>] list of timezone identifiers
        # @see Locales
        def self.getTimezones(name, locales = nil)
            self.new(name).set(locales).getTimezones
        end

        # Get Metazone identifiers for given Rails zone name
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @return [Array<String>] list of metazone identifiers
        # @see Locales
        # @see Regions
        def self.getMetazones(name, locales = nil)
            self.new(name).set(locales).getMetazones
        end

        # Rails zone identifier
        # @param name [String] Rails zone name
        # @param locales [Array<String>] search zone name only for these locales
        # @return [String] Timezone identifier
        def self.getZone(name, locales = nil)
            self.new(name).set(locales).getZone
        end


        protected

        def getFilteredData(dataType)
            params = []
            column = nil
            joins = ''
            regionJoins = ''
            useRegionFilter = !@Regions.nil? && !@Regions.empty?
            case dataType
            when :Zone
                column = '`RailsTimezones`.`Name`'
                joins += ' INNER JOIN `RailsTimezones` ON RailsTimezones.ID = RI.Zone'
            when :Offsets, :Timezones
                column = '`Timezones`.`Name`'
                joins += ' INNER JOIN `RailsTimezones` ON RailsTimezones.ID = RI.Zone'
                joins += ' INNER JOIN `Timezones` ON RailsTimezones.Timezone = Timezones.ID'
                regionJoins += ' LEFT JOIN `TimezoneTerritories` ON TimezoneTerritories.Timezone = RailsTimezones.Timezone'
                regionJoins += ' LEFT JOIN `Territories` ON TimezoneTerritories.Territory = Territories.ID'
            when :Metazones
                raise StandardError, "Metazones is not implemented!"
            when :Types
                raise StandardError, "Types is not implemented!"
            else
                raise StandardError, "Unkown dataType '#{dataType}'"
            end

            if not @Locales.empty?
                joins += ' LEFT JOIN `Locales` AS L ON RI.Locale = L.ID'
                where = 'L.Name COLLATE NOCASE IN (' + Array.new(@Locales.count, '?').join(',')  + ') AND '
                params += @Locales
            end

            sql = 'SELECT DISTINCT ' + column + ' FROM `RailsI18N` AS RI'
            sql += joins
            if useRegionFilter
                sql += regionJoins
            end

            sql += " WHERE #{where}RI.NameLowercase = ?"
            params << @Name.downcase

            if useRegionFilter
                sql += ' AND Territories.Territory IN (' + Array.new(@Regions.count, '?').join(',')  + ')'
                params += @Regions
            end
            sql += ' ORDER BY ' + column

            result = Data::Storage.getStatement(sql).execute(*params).collect { |row| row.first }
            if dataType == :Offsets
                result = self.class.findOffsets(result, @ToTime, @FromTime, @Types)
            end
            result
        end

    end
end
