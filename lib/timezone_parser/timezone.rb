# encoding: utf-8

require 'set'

module TimezoneParser
    # Timezone
    class Timezone < ZoneInfo

        protected
        @@Locales = []
        @@Regions = []

        public
        # Locales which will be used for Timezone methods if not specified there
        #
        # Each locale is language identifier based on IETF BCP 47
        # @return [Array<String>] list containing locale identifiers
        # @see http://en.wikipedia.org/wiki/IETF_language_tag
        # @see http://unicode.org/reports/tr35/#Unicode_Language_and_Locale_Identifiers
        # @see http://www.unicode.org/cldr/charts/latest/supplemental/language_territory_information.html
        def self.Locales
            @@Locales
        end

        # Regions which will be used for Timezone methods if not specified there
        #
        # Each region is CLDR territory (UN M.49)
        # @return [Array<String>] list containing region identifiers
        # @see http://www.unicode.org/cldr/charts/latest/supplemental/territory_containment_un_m_49.html
        def self.Regions
            @@Regions
        end

        attr_accessor :Locales
        attr_accessor :Regions

        # Timezone instance
        # @param timezone [String] Timezone name
        def initialize(timezone)
            @Timezone = timezone
            @Valid = nil
            setTime
            set(@@Locales.dup, @@Regions.dup)
        end

        # Set locales and regions
        # @param locales [Array<String>] search only in these locales
        # @param regions [Array<String>] filter for these regions
        # @return [Timezone] self
        def set(locales = nil, regions = nil)
            @Locales = locales unless locales.nil?
            @Regions = regions unless regions.nil?
            self
        end

        # Check if timezone is valid
        # @return [Boolean] whether timezone is valid
        def isValid?
            if @Valid.nil?
                params = []
                joins = ''
                where = ''

                if not @Locales.empty?
                    joins += ' LEFT JOIN `Locales` AS L ON TN.Locale = L.ID'
                    where = 'L.Name COLLATE NOCASE IN (' + Array.new(@Locales.count, '?').join(',') + ') AND '
                    params += @Locales
                end

                sql = "SELECT 1 FROM `TimezoneNames` TN #{joins} WHERE #{where}TN.NameLowercase = ? COLLATE NOCASE LIMIT 1"
                params << @Timezone.downcase

                @Valid = Data::Storage.getStatement(sql).execute(*params).count > 0
            end
            @Valid
        end

        # Check if given Timezone name is a valid timezone
        # @param timezone [String] Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @return [Boolean] whether Timezone is valid
        # @see Locales
        def self.isValid?(timezone, locales = nil)
            self.new(timezone).set(locales).isValid?
        end

        # Get UTC offsets in seconds for given Timezone name
        # @param timezone [String] Timezone name
        # @param toTime [DateTime] look for offsets which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for offsets which came into effect at this date, inclusive
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for offsets only for these regions
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Locales
        # @see Regions
        def self.getOffsets(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions).getOffsets
        end

        # Get Timezone identifiers for given Timezone name
        # @param timezone [String] Timezone name
        # @param toTime [DateTime] look for timezones which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for timezones which came into effect at this date, inclusive
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for timezones only for these regions
        # @return [Array<String>] list of timezone identifiers
        # @see Locales
        # @see Regions
        def self.getTimezones(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions).getTimezones
        end

        # Get Metazone identifiers for given Timezone name
        # @param timezone [String] Timezone name
        # @param toTime [DateTime] look for timezones which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for timezones which came into effect at this date, inclusive
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for timezones only for these regions
        # @return [Array<String>] list of metazone identifiers
        # @see Locales
        # @see Regions
        def self.getMetazones(timezone, toTime = nil, fromTime = nil, locales = nil, regions = nil)
            self.new(timezone).setTime(toTime, fromTime).set(locales, regions).getMetazones
        end

        protected

        def getFilteredData(dataType)
            params = []
            column = nil
            joins = ''
            regionJoins = ''
            useTimeFilter = false
            useRegionFilter = !@Regions.nil? && !@Regions.empty?
            case dataType
            when :Offsets, :Timezones
                column = '`Timezones`.`Name`'
                if dataType == :Offsets
                    column += ', TN.`Types`'
                end
                joins += ' LEFT JOIN `TimezoneName_Timezones` AS T ON T.Name = TN.ID'
                joins += ' LEFT JOIN `TimezoneName_Metazones` AS M ON M.Name = TN.ID'
                joins += ' LEFT JOIN `MetazonePeriods` MP ON M.Metazone = MP.Metazone'
                joins += ' LEFT JOIN `MetazonePeriod_Timezones` MPT ON MPT.MetazonePeriod = MP.ID'
                joins += ' INNER JOIN `Timezones` ON (T.Timezone = Timezones.ID OR MPT.Timezone = Timezones.ID)'
                regionJoins += ' LEFT JOIN `TimezoneTerritories` ON (TimezoneTerritories.Timezone = T.Timezone OR TimezoneTerritories.Timezone = MPT.Timezone)'
                regionJoins += ' LEFT JOIN `Territories` ON TimezoneTerritories.Territory = Territories.ID'
                useTimeFilter = true
            when :Metazones
                column = '`Metazones`.`Name`'
                joins += ' LEFT JOIN `TimezoneName_Metazones` AS M ON M.Name = TN.ID'
                joins += ' INNER JOIN `Metazones` ON M.Metazone = Metazones.ID'
                regionJoins += ' LEFT JOIN `TimezoneName_Timezones` AS T ON T.Name = TN.ID'
                regionJoins += ' LEFT JOIN `TimezoneTerritories` ON TimezoneTerritories.Timezone = T.Timezone'
                regionJoins += ' LEFT JOIN `Territories` ON TimezoneTerritories.Territory = Territories.ID'
            when :Types
                 column = 'TN.Types'
                 useRegionFilter = false
            else
                raise StandardError, "Unkown dataType '#{dataType}'"
            end

            if not @Locales.empty?
                joins += ' LEFT JOIN `Locales` AS L ON TN.Locale = L.ID'
                where = 'L.Name COLLATE NOCASE IN (' + Array.new(@Locales.count, '?').join(',')  + ') AND '
                params += @Locales
            end

            sql = 'SELECT DISTINCT ' + column + ' FROM `TimezoneNames` AS TN'
            sql += joins
            if useRegionFilter
                sql += regionJoins
            end

            sql += " WHERE #{where}TN.NameLowercase = ?"
            params << @Timezone.downcase
            if useTimeFilter and not @FromTime.nil?
                fromsql = '((MP.`From` IS NULL AND MP.`To` > ?) OR (MP.`To` IS NULL AND MP.`From` <= ?) OR (MP.`From` <= ? AND MP.`To` > ?) OR (MP.`From` IS NULL AND MP.`To` IS NULL))'
                params += Array.new(4, @FromTime.to_s)
                if @ToTime.nil?
                    sql += ' AND ' + fromsql
                end
            end
            if useTimeFilter and not @ToTime.nil?
                tosql = '((MP.`From` IS NULL AND MP.`To` >= ?) OR (MP.`To` IS NULL AND MP.`From` < ?) OR (MP.`From` < ? AND MP.`To` >= ?) OR (MP.`From` IS NULL AND MP.`To` IS NULL))'
                params += Array.new(4, @ToTime.to_s)
                if not @FromTime.nil?
                    sql += ' AND ((' + fromsql + ') OR (' + tosql + '))'
                else
                    sql += ' AND ' + tosql
                end
            end
            if useRegionFilter
                sql += ' AND Territories.Territory IN (' + Array.new(@Regions.count, '?').join(',')  + ')'
                params += @Regions
            end
            sql += ' ORDER BY ' + column

            if dataType == :Offsets
                result = self.class.findOffsetsFromTimezonesTypes(Data::Storage.getStatement(sql).execute(*params), @ToTime, @FromTime, nil)
            else
                result = Data::Storage.getStatement(sql).execute(*params).collect { |row| row.first }
                result = self.class.convertTypes(result) if dataType == :Types
            end
            result
        end

    end
end
