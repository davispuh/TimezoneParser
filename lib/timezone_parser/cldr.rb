# encoding: utf-8
require 'cldr'
require 'cldr/download'
require 'cldr/export/data'
require 'cldr/export/data/timezones'
require 'pathname'

module TimezoneParser
    module CLDR
        @@Version = nil
        DataDir = Pathname.new(Cldr::Export::Data.dir)
        def self.download(source = 'http://unicode.org/Public/cldr/latest/core.zip', target = nil)
            Cldr.download(source, target)
        end

        def self.updateHash(hash, name, data)
            hash[name] ||= []
            hash[name] << data.to_s
            hash[name].uniq!
            hash[name].sort!
            hash
        end

        def self.getVersion(source = DataDir)
            return @@Version if @@Version
            content = File.read(source + 'dtd' + 'ldml.dtd')
            content.gsub!(/<!--.*?-->/, '')
            data = content.match(/\s+cldrVersion\s+[\#\w\s]+\s+"(\d+)"\s*\>/)
            @@Version = data[1].to_i if data
            @@Version
        end

        def self.getTimezones
            timezones = { }
            Cldr::Export::Data.locales.sort.each do |locale|
                tz = Cldr::Export::Data::Timezones.new(locale)
                next if tz.timezones.empty? and tz.metazones.empty?

                tz.timezones.each do |timezone, data|
                    next if timezone == :'Etc/Unknown' or data[:city].nil?
                    city = data[:city].to_s.encode(Encoding::UTF_8).chomp.strip
                    timezones[locale] ||= {}
                    timezones[locale][city] ||= {}
                    self.updateHash(timezones[locale][city], 'Timezones', timezone)
                    data[:long].to_a.each do |type, name|
                        name = name.to_s.encode(Encoding::UTF_8).chomp.strip
                        type = type.to_s.encode(Encoding::UTF_8)
                        timezones[locale][name] ||= {}
                        if type == 'generic'
                            self.updateHash(timezones[locale][name], 'Types', 'standard')
                            self.updateHash(timezones[locale][name], 'Types', 'daylight')
                        else
                            self.updateHash(timezones[locale][name], 'Types', type)
                        end
                        self.updateHash(timezones[locale][name], 'Timezones', timezone.to_s.encode(Encoding::UTF_8))
                    end
                end
                tz.metazones.each do |metazone, data|
                    data[:long].to_a.each do |type, name|
                        name = name.to_s.encode(Encoding::UTF_8).chomp.strip
                        next if name.empty?
                        type = type.to_s.encode(Encoding::UTF_8)
                        timezones[locale] ||= {}
                        timezones[locale][name] ||= {}
                        if type == 'generic'
                            self.updateHash(timezones[locale][name], 'Types', 'standard')
                            self.updateHash(timezones[locale][name], 'Types', 'daylight')
                        else
                            self.updateHash(timezones[locale][name], 'Types', type)
                        end
                        self.updateHash(timezones[locale][name], 'Metazones', metazone.to_s.encode(Encoding::UTF_8))
                    end
                end
                timezones[locale] = Hash[timezones[locale].to_a.sort_by { |d| d.first } ] if timezones[locale]
            end
            timezones
        end

        def self.updateAbbreviations(abbreviations)
            Cldr::Export::Data.locales.sort.each do |locale|
                tz = Cldr::Export::Data::Timezones.new(locale)
                next if tz.timezones.empty? and tz.metazones.empty?
                tz.timezones.each do |timezone, data|
                    data[:short].to_a.each do |type, name|
                        next if name == '∅∅∅'
                        name = name.chomp.strip
                        type = type.to_s.encode(Encoding::UTF_8)
                        abbreviations[name] ||= []
                        data = {}
                        add = true
                        abbreviations[name].each_index do |i|
                            next unless abbreviations[name][i]['Offset'].nil?
                            data = abbreviations[name][i]
                            add = false
                            break
                        end
                        if type == 'generic'
                            self.updateHash(data, 'Types', 'standard')
                            self.updateHash(data, 'Types', 'daylight')
                        else
                            self.updateHash(data, 'Types', type)
                        end
                        self.updateHash(data, 'Timezones', timezone)
                        abbreviations[name] << data if add
                    end
                end
                tz.metazones.each do |metazone, data|
                    data[:short].to_a.each do |type, name|
                        next if name == '∅∅∅'
                        name = name.chomp.strip
                        type = type.to_s.encode(Encoding::UTF_8)
                        abbreviations[name] ||= []
                        data = {}
                        add = true
                        abbreviations[name].each_index do |i|
                            next unless abbreviations[name][i]['Offset'].nil?
                            data = abbreviations[name][i]
                            add = false
                            break
                        end
                        if type == 'generic'
                            self.updateHash(data, 'Types', 'standard')
                            self.updateHash(data, 'Types', 'daylight')
                        else
                            self.updateHash(data, 'Types', type)
                        end
                        self.updateHash(data, 'Metazones', metazone)
                        abbreviations[name] << data if add
                    end
                end
            end
            abbreviations = Hash[abbreviations.to_a.sort_by { |d| d.first } ]
            abbreviations
        end

        def self.getMetazones
            zones = {}
            Cldr::Export::Data::Metazones.new[:timezones].each do |timezone, zonedata|
                zonedata.each do |data|
                    entry = {}
                    add = true
                    zones[data['metazone']] ||= []
                    zones[data['metazone']].each_index do |i|
                        next if zones[data['metazone']][i]['From'].to_s != data['from'].to_s or zones[data['metazone']][i]['To'].to_s != data['to'].to_s
                        entry = zones[data['metazone']][i]
                        add = false
                        break
                    end
                    self.updateHash(entry, 'Timezones', timezone)
                    if add
                        entry['From'] = data['from'].to_s if data['from']
                        entry['To'] = data['to'].to_s if data['to']
                        zones[data['metazone']] << entry
                    end
                    zones[data['metazone']].sort_by! { |d| [d['To'] ? d['To'] : 'zzzz', d['From'] ? d['From'] : ''] }
                end
            end
            zones = Hash[zones.to_a.sort_by { |d| d.first } ]
            zones
        end

        def self.getWindowsZones
            zones = Cldr::Export::Data::WindowsZones.new
            zones = Hash[zones.to_a.sort_by { |d| d.first } ]
            zones
        end
    end
end
