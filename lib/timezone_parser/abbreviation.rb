# encoding: utf-8

module TimezoneParser
    # Timezone abbreviation
    class Abbreviation < ZoneInfo
        protected
        @@Regions = []

        public
        # Regions which will be used for Abbreviation methods if not specified there
        #
        # Each region is either ISO 3166-1 alpha-2 code
        # @return [Array<String>] list containing region identifiers
        # @see http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
        def self.Regions
            @@Regions
        end

        attr_accessor :Regions
        attr_accessor :Type

        # Abbreviation instance
        # @param abbreviation [String] Timezone abbreviation
        def initialize(abbreviation)
            @Abbreviation = abbreviation
            setTime
            set(@@Regions.dup, nil)
        end

        # Set regions and type
        # @param regions [Array<String>] filter for these regions
        # @param type [Symbol] filter by type, :standard time or :daylight
        # @return [Abbreviation] self
        # @see Regions
        def set(regions = nil, type = nil)
            @Regions = regions unless regions.nil?
            @Type = type.to_sym if type
            self
        end

        # Check if abbreviation is valid
        # @return [Boolean] whether abbreviation is valid
        def isValid?
            if @Valid.nil?
                sql = 'SELECT 1 FROM `Abbreviations` WHERE `Name` = ? LIMIT 1'
                @Valid = Data::Storage.getStatement(sql).execute(@Abbreviation).count > 0
            end
            @Valid
        end

        # Check if given Timezone abbreviation (case-sensitive) is a valid timezone
        # @param abbreviation [String] Timezone abbreviation
        # @return [Boolean] whether Timezone is valid
        def self.isValid?(abbreviation)
            Data::Storage.getStatement('SELECT 1 FROM `Abbreviations` WHERE `Name` = ? LIMIT 1').execute(abbreviation).count > 0
        end

        # Check if given Timezone abbreviation (case-insensitive) could be a valid timezone
        # @param abbreviation [String] Timezone abbreviation to check for
        # @return [Boolean] whether Timezone is valid
        def self.couldBeValid?(abbreviation)
            Data::Storage.getStatement('SELECT 1 FROM `Abbreviations` WHERE `NameLowercase` = ? LIMIT 1').execute(abbreviation.downcase).count > 0
        end

        # Get UTC offsets in seconds for given Timezone abbreviation
        # @param abbreviation [String] Timezone abbreviation
        # @param toTime [DateTime] look for offsets which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for offsets which came into effect at this date, inclusive
        # @param regions [Array<String>] look for offsets only for these regions
        # @param type [Symbol] specify whether offset should be :standard time or :daylight
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Regions
        def self.getOffsets(abbreviation, toTime = nil, fromTime = nil, regions = nil, type = nil)
            self.new(abbreviation).setTime(toTime, fromTime).set(regions, type).getOffsets
        end

        # Get Timezone identifiers for given Timezone abbreviation
        # @param abbreviation [String] Timezone abbreviation
        # @param toTime [DateTime] look for timezones which came into effect before this date, exclusive
        # @param fromTime [DateTime] look for timezones which came into effect at this date, inclusive
        # @param regions [Array<String>] look for timezones only for these regions
        # @param type [Symbol] specify whether timezones should be :standard time or :daylight
        # @return [Array<String>] list of timezone identifiers
        # @see Regions
        def self.getTimezones(abbreviation, toTime = nil, fromTime = nil, regions = nil, type = nil)
            self.new(abbreviation).setTime(toTime, fromTime).set(regions, type).getTimezones
        end

        # Get Metazone identifiers for given Timezone abbreviation
        # @param abbreviation [String] Timezone abbreviation
        def self.getMetazones(abbreviation)
            self.new(abbreviation).getMetazones
        end

        protected

        def getFilteredData(dataType)
            types = nil
            types = [@Type] if @Type

            params = [@Abbreviation.downcase]
            column = nil
            joins = ' INNER JOIN `AbbreviationOffsets` AS O ON O.Abbreviation = A.ID'
            regionJoins = ''
            useMetazonePeriodFilter = false
            case dataType
            when :Offsets, :Timezones
                column = '`Timezones`.`Name`'
                if dataType == :Offsets
                    column = 'O.`Offset`, `Timezones`.`Name`, O.`Types`'
                end
                joins += ' LEFT JOIN `AbbreviationOffset_Timezones` AS T ON T.Offset = O.ID'
                joins += ' LEFT JOIN `AbbreviationOffset_Metazones` AS M ON M.Offset = O.ID'
                joins += ' LEFT JOIN `MetazonePeriods` MP ON M.Metazone = MP.Metazone'
                joins += ' LEFT JOIN `MetazonePeriod_Timezones` MPT ON MPT.MetazonePeriod = MP.ID'
                joins += ' LEFT JOIN `Timezones` ON (T.Timezone = Timezones.ID OR MPT.Timezone = Timezones.ID)'
                regionJoins += ' LEFT JOIN `TimezoneTerritories` ON (TimezoneTerritories.Timezone = T.Timezone OR TimezoneTerritories.Timezone = MPT.Timezone)'
                regionJoins += ' LEFT JOIN `Territories` ON TimezoneTerritories.Territory = Territories.ID'
                useMetazonePeriodFilter = true
            when :Metazones
                column = '`Metazones`.`Name`'
                joins += ' INNER JOIN `AbbreviationOffset_Metazones` AS M ON M.Offset = O.ID'
                joins += ' INNER JOIN `Metazones` ON M.Metazone = Metazones.ID'
                regionJoins += ' LEFT JOIN `AbbreviationOffset_Timezones` AS T ON T.Offset = O.ID'
                regionJoins += ' LEFT JOIN `TimezoneTerritories` ON TimezoneTerritories.Timezone = T.Timezone'
                regionJoins += ' LEFT JOIN `Territories` ON TimezoneTerritories.Territory = Territories.ID'
            when :Types
                 column = 'O.`Types`'
            else
                raise StandardError, "Unkown dataType '#{dataType}'"
            end
            sql = 'SELECT DISTINCT ' + column + ' FROM `Abbreviations` AS A'
            sql += joins
            if not @Regions.nil? and not @Regions.empty?
                sql += regionJoins
            end
            sql += ' WHERE A.`NameLowercase` = ?'
            if not types.nil?
                if types.include?(:standard) and not types.include?(:daylight)
                    sql += ' AND (O.`Types` & ?) > 0'
                    params << TIMEZONE_TYPE_STANDARD

                else
                    sql += ' AND (O.`Types` & ?) > 0'
                    params << TIMEZONE_TYPE_DAYLIGHT
                end
            end
            unless @FromTime.nil?
                fromsql = '((O.`From` IS NULL AND O.`To` > ?) OR (O.`To` IS NULL AND O.`From` <= ?) OR (O.`From` <= ? AND O.`To` > ?) OR (O.`From` IS NULL AND O.`To` IS NULL))'
                params += Array.new(4, @FromTime.to_s)
                if useMetazonePeriodFilter
                    fromsql = '(' + fromsql + ' AND ((MP.`From` IS NULL AND MP.`To` > ?) OR (MP.`To` IS NULL AND MP.`From` <= ?) OR (MP.`From` <= ? AND MP.`To` > ?) OR (MP.`From` IS NULL AND MP.`To` IS NULL)))'
                    params += Array.new(4, @FromTime.to_s)
                end
                if @ToTime.nil?
                    sql += ' AND ' + fromsql
                end
            end
            unless @ToTime.nil?
                tosql = '((O.`From` IS NULL AND O.`To` >= ?) OR (O.`To` IS NULL AND O.`From` < ?) OR (O.`From` < ? AND O.`To` >= ?) OR (O.`From` IS NULL AND O.`To` IS NULL))'
                params += Array.new(4, @ToTime.to_s)
                if useMetazonePeriodFilter
                    tosql = '(' + tosql + ' AND ((MP.`From` IS NULL AND MP.`To` >= ?) OR (MP.`To` IS NULL AND MP.`From` < ?) OR (MP.`From` < ? AND MP.`To` >= ?) OR (MP.`From` IS NULL AND MP.`To` IS NULL)))'
                    params += Array.new(4, @ToTime.to_s)
                end
                if not @FromTime.nil?
                    sql += ' AND ((' + fromsql + ') OR (' + tosql + '))'
                else
                    sql += ' AND ' + tosql
                end
            end
            if not @Regions.nil? and not @Regions.empty?
                sql += ' AND Territories.Territory IN (' + Array.new(@Regions.count, '?').join(',')  + ')'
                params += @Regions
            end
            sql += ' ORDER BY ' + column
            if dataType == :Offsets
                result = Set.new
                timezonesTypes = []
                Data::Storage.getStatement(sql).execute(*params).each do |row|
                    if row.first.nil?
                        timezonesTypes << [row[1], row[2]]
                    else
                        result << row.first
                    end
                end

                result += self.class.findOffsetsFromTimezonesTypes(timezonesTypes, @ToTime, @FromTime, types) if result.empty?

                result = result.sort
            else
                result = Data::Storage.getStatement(sql).execute(*params).collect { |row| row.first }
                if dataType == :Types
                    result = self.class.convertTypes(result)
                end
            end
            result
        end

    end
end
