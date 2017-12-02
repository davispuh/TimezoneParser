# encoding: utf-8

module TimezoneParser
    # Windows Timezone
    class WindowsZone < ZoneInfo
        protected
        @@Locales = []
        @@Regions = []

        public
        # Locales which will be used for WindowsZone methods if not specified there
        #
        # Each locale consists of language identifier and country/region identifier
        # @return [Array<String>] list containing locale identifiers
        # @see http://msdn.microsoft.com/en-us/library/dd318693.aspx
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

        # Windows Timezone instance
        # @param name [String] Windows Timezone name
        def initialize(name)
            @Name = name
            @Valid = nil
            set(@@Locales.dup, @@Regions.dup)
        end

        # Set locales and regions
        # @param locales [Array<String>] search only in these locales
        # @param regions [Array<String>] filter for these regions
        # @return [WindowsZone] self
        # @see Locales
        # @see Regions
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

                sql = "SELECT 1 FROM `WindowsZoneNames` TN #{joins} WHERE #{where}TN.`NameLowercase` = ? LIMIT 1"
                params << @Name.downcase

                @Valid = Data::Storage.getStatement(sql).execute(*params).count > 0
            end
            @Valid
        end

        # Windows Timezone identifier
        # @return [String] Timezone identifier
        def getZone
            unless @Zone
                @Zone = self.getFilteredData(:Zone).first
            end
            @Zone
        end

        # Check if given Windows Timezone name is a valid timezone
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @return [Boolean] whether Timezone is valid
        # @see Locales
        def self.isValid?(name, locales = nil)
            self.new(name).set(locales).isValid?
        end

        # Get UTC offsets in seconds for given Windows Timezone name
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @return [Array<Fixnum>] list of timezone offsets in seconds
        # @see Locales
        def self.getOffsets(name, locales = nil)
            self.new(name).set(locales, nil).getOffsets
        end

        # Get Timezone identifiers for given Windows Timezone name
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @param regions [Array<String>] look for timezones only for these regions
        # @return [Array<String>] list of timezone identifiers
        # @see Locales
        # @see Regions
        def self.getTimezones(name, locales = nil, regions = nil)
            self.new(name).set(locales, regions).getTimezones
        end

        # Get Metazone identifiers for given Windows Timezone name
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @return [Array<String>] list of metazone identifiers
        # @see Locales
        def self.getMetazones(name, locales = nil)
            self.new(name).set(locales, nil).getMetazones
        end

        # Windows Timezone identifier
        # @param name [String] Windows Timezone name
        # @param locales [Array<String>] search Timezone name only for these locales
        # @return [String] Timezone identifier
        def self.getZone(name, locales = nil)
            self.new(name).set(locales, nil).getZone
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
                column = '`WindowsZones`.`Name`'
                joins += ' LEFT JOIN `WindowsZoneName_Zones` AS NameZones ON NameZones.Name = ZN.ID'
                joins += ' INNER JOIN `WindowsZones` ON WindowsZones.ID = NameZones.Zone'
            when :Offsets
                column = '`WindowsZones`.`Standard`, `WindowsZones`.`Daylight`, ZN.`Types`'
                joins += ' LEFT JOIN `WindowsZoneName_Zones` AS NameZones ON NameZones.Name = ZN.ID'
                joins += ' INNER JOIN `WindowsZones` ON WindowsZones.ID = NameZones.Zone'
            when :Timezones
                column = '`Timezones`.`Name`'
                joins += ' LEFT JOIN `WindowsZoneName_Zones` AS NameZones ON NameZones.Name = ZN.ID'
                joins += ' INNER JOIN `WindowsZone_Timezones` ZoneTimezones ON ZoneTimezones.Zone = NameZones.Zone'
                joins += ' INNER JOIN `Timezones` ON ZoneTimezones.Timezone = Timezones.ID'
                regionJoins += ' LEFT JOIN `Territories` ON ZoneTimezones.Territory = Territories.ID'
            when :Metazones
                raise StandardError, "Metazones is not implemented!"
            when :Types
                column = 'ZN.`Types`'
                useRegionFilter = false
            else
                raise StandardError, "Unkown dataType '#{dataType}'"
            end

            if not @Locales.empty?
                joins += ' LEFT JOIN `Locales` AS L ON ZN.Locale = L.ID'
                where = 'L.Name COLLATE NOCASE IN (' + Array.new(@Locales.count, '?').join(',')  + ') AND '
                params += @Locales
            end

            sql = 'SELECT DISTINCT ' + column + ' FROM `WindowsZoneNames` AS ZN'
            sql += joins
            if useRegionFilter
                sql += regionJoins
            end

            sql += " WHERE #{where}ZN.NameLowercase = ?"
            params << @Name.downcase

            if useRegionFilter
                sql += ' AND Territories.Territory IN (' + Array.new(@Regions.count, '?').join(',')  + ')'
                params += @Regions
            end
            sql += ' ORDER BY ' + column

            if dataType == :Offsets
                allOffsets = Set.new
                Data::Storage.getStatement(sql).execute(*params).each do |row|
                    allOffsets << row[0] if not (row.last & 0x01).zero?
                    allOffsets << row[1] if not (row.last & 0x02).zero?
                end
                result = allOffsets.sort
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
