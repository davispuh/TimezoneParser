# encoding: utf-8
require 'win32/registry'
require 'fiddle'

module TimezoneParser
    # Windows module
    module Windows

        protected

        @@Version = nil
        @@Errors = ''

        public
        # Windows Registry path to Time Zone data
        TimeZonePath = 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones'
        def self.errors
            @@Errors
        end

        def self.getVersion(path = TimeZonePath)
            return @@Version if @@Version
            begin
                Win32::Registry::HKEY_LOCAL_MACHINE.open(path, Win32::Registry::KEY_READ) do |reg|
                    @@Version = reg['TzVersion', Win32::Registry::REG_DWORD].to_s(16)
                end
            rescue Win32::Registry::Error => e
                @@Errors << e.message
            end
            @@Version
        end

        def self.getTimezones(path = TimeZonePath)
            timezones = {}

            timezones['North Pacific Standard Time'] = { 'standard' => 3600 * -8, 'daylight' => 3600 * -7 }
            timezones['Russia TZ 5 Standard Time']   = { 'standard' => 3600 *  6, 'daylight' => 3600 *  6 }

            begin
                Win32::Registry::HKEY_LOCAL_MACHINE.open(path, Win32::Registry::KEY_READ).each_key do |key, wtime|
                    Win32::Registry::HKEY_LOCAL_MACHINE.open(path + '\\' + key, Win32::Registry::KEY_READ) do |reg|
                        timezones[key] ||= {}
                        tzi = reg.read('TZI', Win32::Registry::REG_BINARY).last
                        # TZI Structure (http://msdn.microsoft.com/en-us/library/windows/desktop/ms725481.aspx)
                        # typedef struct _REG_TZI_FORMAT
                        # {
                        #    LONG Bias;
                        #    LONG StandardBias;
                        #    LONG DaylightBias;
                        #    SYSTEMTIME StandardDate;
                        #    SYSTEMTIME DaylightDate;
                        # } REG_TZI_FORMAT;
                        unpacked = tzi.unpack('lllSSSSSSSSSSSSSSSS')
                        timezones[key]['standard'] = (0 - unpacked[0] - unpacked[1]) * 60
                        timezones[key]['daylight'] = (0 - unpacked[0] - unpacked[2]) * 60
                    end
                end
            rescue Win32::Registry::Error => e
                @@Errors << e.message
            end

            timezones = Hash[timezones.to_a.sort_by { |d| d.first } ]
            timezones
        end

        def self.getTimezonesUTC()
            timezones = {}
            ((1..13).to_a + (-12..-1).to_a.reverse).each do |o|
                name = "UTC%+03d" % o
                timezones[name] = { 'standard' => 3600 * o }
                timezones[name]['daylight'] = timezones[name]['standard']
            end
            timezones
        end

        def self.getMUIOffsets(path = TimeZonePath)
            offsets = {}
            begin
                Win32::Registry::HKEY_LOCAL_MACHINE.open(path, Win32::Registry::KEY_READ).each_key do |key, wtime|
                    Win32::Registry::HKEY_LOCAL_MACHINE.open(path + '\\' + key, Win32::Registry::KEY_READ) do |reg|
                        muiDisplay = reg.read_s('MUI_Display')
                        muiDlt = reg.read_s('MUI_Dlt')
                        muiStd = reg.read_s('MUI_Std')

                        offsets[self.parseMUI(muiDisplay)] = { 'Type' => 'display', 'Name' => key }
                        offsets[self.parseMUI(muiDlt)] = { 'Type' => 'daylight', 'Name' => key }
                        offsets[self.parseMUI(muiStd)] = { 'Type' => 'standard', 'Name' => key }
                    end
                end
            rescue Win32::Registry::Error => e
                @@Errors << e.message
            end
            puts @@Errors unless @@Errors.empty?
            Hash[offsets.to_a.sort_by { |o| o.first }]
        end

        def self.parseMUI(str)
            parts = str.split(',')
            puts "Warning: Unexpected dll name #{parts.first}" if parts.first != '@tzres.dll'
            parts.last.to_i.abs
        end

        def self.getLocales(lcids)
            locales = {}
            lcids.each do |lcid|
                localeMem = Fiddle::Pointer.malloc(LOCALE_NAME_MAX_LENGTH)
                chars = LCIDToLocaleName.call(lcid, localeMem, LOCALE_NAME_MAX_LENGTH, 0)
                if chars.zero?
                    puts "Warning: Failed to translate LCID (#{lcid}) to locale name!"
                    next
                end
                locale = localeMem.to_s((chars-1)*2).force_encoding(Encoding::UTF_16LE).encode(Encoding::UTF_8)
                locales[lcid] = locale
            end
            locales
        end

        def self.collectMUIOffsets(metazoneList, locales)
            enUS = locales.key('en-US')
            baseMetazone = metazoneList[enUS]
            types = ['display', 'daylight', 'standard']
            type_bases = [0, 0, 0, 3, 3, 3, nil, 7, 7, 7]
            offsets = {}
            baseMetazone.each do |id, name|
                data = {}
                type = id % 10
                type_base = type_bases[type]
                data['Type'] = types[type - type_base]
                data['Name'] = baseMetazone[(id / 10) * 10 + type_base + types.index('standard')]
                offsets[id] = data unless data['Name'].nil?
            end
            Hash[offsets.to_a.sort_by { |o| o.first }]
        end

        def self.correctMUIOffsetNames(offsets, metazoneList, locales)
            enUS = locales.key('en-US')
            baseMetazone = metazoneList[enUS]
            offsets.each do |id, data|
                actualMetazone = nil
                baseMetazone.each do |zoneid, name|
                    if id != zoneid and name == data['Name']
                        actualMetazone = offsets[zoneid]['Name']
                        break
                    end
                end
                data['Name'] = actualMetazone if actualMetazone
            end
            offsets
        end

        def self.parseMetazones(metazoneList, offsets, locales)
            metazones = {}
            metazoneList.each do |lcid, data|
                locale = locales[lcid]
                if locale.nil?
                    puts "Warning: No translation to locale name from LCID (#{lcid}), skipping!"
                    next
                end
                metazones[locale] = {}
                offsets.each do |id, info|
                    unless data.has_key?(id)
                        puts "Warning: Didn't found timezone name for #{id} for #{locale} locale, skipping!"
                        next
                    end
                    name = data[id]
                    metazones[locale][name] ||= {}
                    metazones[locale][name]['Types'] ||= []
                    metazones[locale][name]['Metazones'] ||= []
                    types = []
                    types << info['Type'] if info.has_key?('Type')
                    if info['Type'] == 'display'
                        types = ['daylight', 'standard']
                    end
                    metazones[locale][name]['Types'] += types
                    metazones[locale][name]['Metazones'] << info['Name']
                    metazones[locale][name]['Types'].uniq!
                    metazones[locale][name]['Metazones'].uniq!
                end
                metazones[locale] = Hash[metazones[locale].to_a.sort_by { |d| d.first } ]
            end
            metazones = Hash[metazones.to_a.sort_by { |d| d.first } ]
            metazones
        end

        # Windows Kernel32 library
        kernel32 = Fiddle.dlopen('kernel32')

        # function
        # int LCIDToLocaleName (
        # _In_       LCID Locale,
        # _Out_opt_  LPWSTR lpName,
        # _In_       int cchName,
        # _In_       DWORD dwFlags
        # );
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/dd318698.aspx
        LCIDToLocaleName = Fiddle::Function.new( kernel32['LCIDToLocaleName'],
        [Fiddle::TYPE_LONG, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_LONG], Fiddle::TYPE_INT )
        # Max locale length
        LOCALE_NAME_MAX_LENGTH = 85
    end
end
