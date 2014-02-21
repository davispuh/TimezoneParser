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

        def self.getMUIOffsets(path = TimeZonePath)
            offsets = {}
            begin
                Win32::Registry::HKEY_LOCAL_MACHINE.open(path, Win32::Registry::KEY_READ).each_key do |key, wtime|
                    Win32::Registry::HKEY_LOCAL_MACHINE.open(path + '\\' + key, Win32::Registry::KEY_READ) do |reg|
                        muiDlt = reg.read_s('MUI_Dlt')
                        muiStd = reg.read_s('MUI_Std')

                        offsets[self.parseMUI(muiDlt)] = ['daylight', key]
                        offsets[self.parseMUI(muiStd)] = ['standard', key]
                    end
                end
            rescue Win32::Registry::Error => e
                @@Errors << e.message
            end
            puts @@Errors
            offsets
        end

        def self.parseMUI(str)
            str.split(',').last.to_i.abs
        end

        def self.parseMetazones(metazoneList, offsets)
            metazones = {}
            metazoneList.each do |lcid, data|
                localeMem = Fiddle::Pointer.malloc(LOCALE_NAME_MAX_LENGTH)
                chars = LCIDToLocaleName.call(lcid, localeMem, LOCALE_NAME_MAX_LENGTH, 0)
                return nil if chars.zero?
                locale = localeMem.to_s((chars-1)*2).force_encoding(Encoding::UTF_16LE).encode(Encoding::UTF_8)
                metazones[locale] = {}
                offsets.each do |id, info|
                    name = data[id]
                    metazones[locale][name] ||= {}
                    metazones[locale][name]['Types'] ||= []
                    metazones[locale][name]['Metazones'] ||= []
                    metazones[locale][name]['Types'] << info.first
                    metazones[locale][name]['Metazones'] << info.last
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
