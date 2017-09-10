# encoding: utf-8
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'yard'
require 'yaml'
require 'pathname'
require 'timezone_parser/data'

desc 'Default: run specs.'
task :default => :spec

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec) do |t|
end

YARD::Rake::YardocTask.new(:doc) do |t|
end

def data_location
    TimezoneParser::Data::DataDir
end

def vendor_location
    TimezoneParser::Data::VendorDir
end

def repo_location
    TimezoneParser::Data::RootDir
end

def write_yaml(filename, data)
    options = { :cr_newline => false, :encoding => 'UTF-8:UTF-8' }
    File.write(filename, data.to_yaml, options)
end

def update
    require 'timezone_parser/data/tzinfo'
    require 'timezone_parser/data/cldr'
    require 'active_support/version'
    require 'active_support/time'
    TimezoneParser::TZInfo::init
    countries = TimezoneParser::TZInfo::getTimezoneCountries
    abbreviations = TimezoneParser::TZInfo::getAbbreviations
    timezones = TimezoneParser::CLDR::getTimezones
    metazones = TimezoneParser::CLDR::getMetazones
    windowsZones = TimezoneParser::CLDR::getWindowsZones
    TimezoneParser::CLDR::updateAbbreviations(abbreviations)
    version = YAML.load_file(data_location + 'version.yaml')
    version['TZInfo'] = TimezoneParser::TZInfo::getVersion
    version['CLDR'] = TimezoneParser::CLDR::getVersion
    version['Rails'] = ActiveSupport::VERSION::STRING
    version['WindowsZones'] = nil unless version.has_key?('WindowsZones')
    write_yaml(data_location + 'countries.yaml', countries)
    write_yaml(data_location + 'timezones.yaml', timezones)
    write_yaml(data_location + 'metazones.yaml', metazones)
    write_yaml(data_location + 'windows_timezones.yaml', windowsZones)
    abbreviations = Hash[abbreviations.to_a.sort_by { |d| d.first } ]
    write_yaml(data_location + 'abbreviations.yaml', abbreviations)
    rails = Hash[ActiveSupport::TimeZone::MAPPING.to_a.sort_by { |d| d.first } ]
    write_yaml(data_location + 'rails.yaml', rails)
    write_yaml(data_location + 'version.yaml', version)
end

def update_rails
    timezone_path = repo_location + 'i18n-timezones' + 'rails' + 'locale'
    names = {}
    timezone_path.each_child(false) do |file|
        YAML.load_file(timezone_path + file).each do |locale, data|
            namesArray = data['timezones'].invert.to_a
            namesArray.each { |e| e.map!(&:strip) }
            names[locale] = Hash[namesArray.sort_by { |d| d.first } ]
        end
    end
    names = Hash[names.to_a.sort_by { |d| d.first } ]
    write_yaml(data_location + 'rails_i18n.yaml', names)
end

def update_windows
    os = Gem::Platform.local.os
    if (os == 'mingw32' or os == 'mingw64')
        require 'timezone_parser/data/windows'
        version = YAML.load_file(data_location + 'version.yaml')
        version['WindowsZones'] = TimezoneParser::Windows.getVersion
        if version['WindowsZones'].nil?
            $stderr.puts TimezoneParser::Windows.errors
        else
            timezones = TimezoneParser::Windows.getTimezonesUTC
            timezones.merge!(TimezoneParser::Windows.getTimezones)
            timezones = Hash[timezones.to_a.sort_by { |d| d.first } ]
            write_yaml(data_location + 'windows_offsets.yaml', timezones)
            write_yaml(data_location + 'version.yaml', version)
        end
    else
        puts 'Skipped Windows Zone update. Need to be run from Windows.'
    end
end

def update_windows_mui
    os = Gem::Platform.local.os
    if (os == 'mingw32' or os == 'mingw64')
        tzres = data_location + 'windows_tzres.yaml'
        require 'timezone_parser/data/windows'
        offsets = YAML.load_file(tzres)
        offsets.merge!(TimezoneParser::Windows.getMUIOffsets)
        write_yaml(tzres, offsets)
    else
        puts 'Can update Windows tzres MUI offsets only from Windows!'
    end
end

def update_windows_mui_extended(metazones, locales)
    tzres = data_location + 'windows_tzres.yaml'
    offsets = YAML.load_file(tzres)
    offsets.merge!(TimezoneParser::Windows.collectMUIOffsets(metazones, locales))
    write_yaml(tzres, offsets)
    update_windows_mui
    offsets = YAML.load_file(tzres)
    TimezoneParser::Windows.correctMUIOffsetNames(offsets, metazones, locales)
    write_yaml(tzres, offsets)
end

def import_timezones
    os = Gem::Platform.local.os
    if (os == 'mingw32' or os == 'mingw64')
        timeZoneFile = vendor_location + 'tzres.yaml'
        unless File.exist?(timeZoneFile)
          puts 'File `tzres.yaml` not found. Windows Zone name importing skipped.'
          return
        end
        require 'timezone_parser/data/windows'
        metazones = YAML.load_file(timeZoneFile)
        locales = TimezoneParser::Windows.getLocales(metazones.keys.sort)
        write_yaml(data_location + 'windows_locales.yaml', locales)
        update_windows_mui_extended(metazones, locales)
        tzres = data_location + 'windows_tzres.yaml'
        offsets = YAML.load_file(tzres)
        metazone_names = TimezoneParser::Windows.parseMetazones(metazones, offsets, locales)
        write_yaml(data_location + 'windows_zonenames.yaml', metazone_names)
    else
        puts 'Can\'t import Windows Zone names. Need to be run from Windows.'
    end
end

def download_tz
    require 'timezone_parser/data/tzinfo'
    TimezoneParser::TZInfo::download
end

def download_cldr
    require 'timezone_parser/data/cldr'
    TimezoneParser::CLDR::download
end

desc 'Download TZ data'
task 'download:tz' do
    download_tz
end

desc 'Download CLDR data'
task 'download:cldr' do
    download_cldr
end

desc 'Download TZ and CLDR data'
task :download do
    download_tz
    download_cldr
end

desc 'Update data'
task :update do
    update
end

desc 'Update Rails data'
task 'update:rails' do
    update_rails
end

desc 'Update Windows data'
task 'update:windows' do
    update_windows
end

desc 'Update Windows tzres MUI'
task 'update:windows_mui' do
    update_windows_mui
end

desc 'Import Windows localized timezones from tzres.yaml'
task 'update:windowszones' do
    import_timezones
end

desc 'Update all data'
task 'update:all' do
    update
    update_rails
    update_windows
    import_timezones
end

desc 'Export data'
task 'export' do
    ['abbreviations.yaml', 'timezones.yaml', 'countries.yaml', 'metazones.yaml',
        'windows_zonenames.yaml', 'windows_timezones.yaml', 'windows_offsets.yaml',
        'rails.yaml', 'rails_i18n.yaml'].each do |name|
        path = data_location + name
        Marshal.dump(YAML.load_file(path), File.open(path.dirname + (path.basename('.*').to_s + '.dat'), 'wb'))
    end
end
