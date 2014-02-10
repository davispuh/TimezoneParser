# encoding: utf-8
require 'tzinfo'
require 'tzinfo/data/tzdataparser'
require 'uri'
require 'open-uri'
require 'rubygems/package'
require 'zlib'
require 'yaml'
require 'pathname'
require 'timezone_parser/data'

module TimezoneParser
    module TZInfo
        TZDataSource = 'ftp://ftp.iana.org/tz/tzdata-latest.tar.gz'
        TZDataPath = TimezoneParser::Data::VendorDir + 'zoneinfo'
        TZInfoData = TimezoneParser::Data::VendorDir + 'tzinfo'
        LastTimestamp = 2147483647
        @@Version = nil
        @@TimezoneCountries = nil
        def self.download(source = TZDataSource, location = TZDataPath, target = TZInfoData)
            URI.parse(source).open do |tempfile|
                FileUtils.mkdir_p(location)
                tar = Gem::Package::TarReader.new(Zlib::GzipReader.open(tempfile.path))
                tar.each do |entry|
                    path = location + entry.full_name
                    FileUtils.mkdir_p(path.dirname)
                    if entry.file?
                        File.open(path, 'wb') do |file|
                            file.write(entry.read)
                        end
                    end
                end
                tar.close
            end
            parser = ::TZInfo::Data::TZDataParser.new(location, target)
            parser.execute
            getVersion(location)
        end

        def self.getVersion(source = TZDataPath)
            return @@Version if @@Version
            File.open(source + 'Makefile', 'r', { :encoding => 'UTF-8:UTF-8' }) do |file|
                file.each_line do |line|
                    line = line.gsub(/#.*$/, '')
                    v = line.match(/^\s*VERSION\s*=\s*(\w+)\s*$/)
                    @@Version = v[1] if v
                end
            end
            @@Version
        end

        def self.init
            ::TZInfo::DataSource.set(:ruby, TZInfoData)
        end

        def self.getTimezoneCountries
            unless @@TimezoneCountries
                @@TimezoneCountries = {}
                ::TZInfo::Country.all.each do |countryData|
                    countryData.zone_identifiers.each do |timezone|
                        @@TimezoneCountries[timezone] ||= []
                        @@TimezoneCountries[timezone] << countryData.code
                        @@TimezoneCountries[timezone].uniq!
                        @@TimezoneCountries[timezone].sort!
                    end
                end
                @@TimezoneCountries = Hash[@@TimezoneCountries.to_a.sort_by { |pair| pair.first }]
            end
            @@TimezoneCountries
        end

        def self.getAbbreviations
            transitionData = {}
            ::TZInfo::Timezone.all_data_zone_identifiers.each do |name|
                zone = ::TZInfo::Timezone.get(name)
                zone_transitions = zone.transitions_up_to(Time.at(LastTimestamp))
                zone_transitions.each_index do |i|
                    offset = zone_transitions[i].offset
                    next if offset.abbreviation == :LMT or offset.abbreviation == :zzz
                    abbr = offset.abbreviation.to_s
                    transitionData[abbr] = [] unless transitionData[abbr]
                    period = ::TZInfo::TimezonePeriod.new(zone_transitions[i], zone_transitions[i+1])
                    transitionData[abbr] << { :name => name, :period => period }
                end
            end
            timezoneData = {}
            transitionData.keys.sort.each do |name|
                transitions = []
                transitionData[name].each do |transition|
                    period_start = transition[:period].utc_start
                    period_start = period_start.to_s
                    period_end = transition[:period].utc_end
                    period_end = period_end.to_s if period_end
                    timezone = transition[:name]
                    countries = getTimezoneCountries[timezone]
                    countries = countries.dup if countries
                    data = { 'Offset' => transition[:period].utc_total_offset,  'Timezones' => [timezone], 'Countries' => countries, 'From' => period_start }
                    data['To'] = period_end if period_end
                    transitions << data
                end
                transitions.sort_by! { |data| [data['To'] ? data['To'] : 'zzzz', data['From']] }

                abbreviationData = []
                abbreviationData << transitions.shift
                transitions.each do |data|
                    current = abbreviationData.last
                    if data['Offset'] == current['Offset'] and (current['Timezones'].sort == data['Timezones'].sort || (data['From'] == current['From'] and data['To'] == current['To']))
                        current['Timezones'] += data['Timezones']
                        current['Timezones'].uniq!
                        current['Timezones'].sort!
                        if data['Countries']
                            current['Countries'] = current['Countries'].to_a + data['Countries']
                            current['Countries'].uniq!
                            current['Countries'].sort!
                        end
                        current['To'] = data['To']
                        current.delete('To') unless current['To']
                    else
                        abbreviationData << data
                    end
                end
                previous = nil
                abbreviationData.delete_if do |item|
                    if previous.nil?
                        previous = item
                        false
                    elsif previous['Offset'] == item['Offset'] and previous['Timezones'] == item['Timezones']
                        previous['To'] = item['To']
                        previous.delete('To') unless previous['To']
                        true
                    else
                        previous = item
                        false
                    end
                end
                timezoneData[name] = abbreviationData
            end
            timezoneData
        end
    end
end
