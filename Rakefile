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
    TimezoneParser::Data::RootDir.parent.parent
end

def update
    require 'timezone_parser/data/tzinfo'
    require 'timezone_parser/data/cldr'
    require 'active_support/time'
    TimezoneParser::TZInfo::init
    countries = TimezoneParser::TZInfo::getTimezoneCountries
    abbreviations = TimezoneParser::TZInfo::getAbbreviations
    timezones = TimezoneParser::CLDR::getTimezones
    metazones = TimezoneParser::CLDR::getMetazones
    windowsZones = TimezoneParser::CLDR::getWindowsZones
    TimezoneParser::CLDR::updateAbbreviations(abbreviations)
    version = { 'TZInfo' => TimezoneParser::TZInfo::getVersion, 'CLDR' => TimezoneParser::CLDR::getVersion, 'Rails' => ActiveSupport::VERSION::STRING, 'WindowsZones' => nil }
    File.write(data_location + 'countries.yml', countries.to_yaml)
    File.write(data_location + 'timezones.yml', timezones.to_yaml)
    File.write(data_location + 'metazones.yml', metazones.to_yaml)
    File.write(data_location + 'windows_timezones.yml', windowsZones.to_yaml)
    abbreviations = Hash[abbreviations.to_a.sort_by { |d| d.first } ]
    File.write(data_location + 'abbreviations.yml', abbreviations.to_yaml)
    rails = Hash[ActiveSupport::TimeZone::MAPPING.to_a.sort_by { |d| d.first } ]
    File.write(data_location + 'rails.yml', rails.to_yaml)
    File.write(data_location + 'version.yml', version.to_yaml)
end

def update_rails
    timezone_path = repo_location + 'i18n-timezones' + 'rails' + 'locale'
    names = {}
    timezone_path.each_child(false) do |file|
        YAML.load_file(timezone_path + file).each do |locale, data|
            namesArray = data['timezones'].invert.to_a
            namesArray.map { |e| e.map!(&:strip) }
            names[locale] = Hash[namesArray.sort_by { |d| d.first } ]
        end
    end
    File.write(data_location + 'rails_i18n.yml', names.to_yaml)
end

def update_windows
    os = Gem::Platform.local.os
    if (os == 'mingw32' or os == 'mingw64')
        require 'timezone_parser/data/windows'
        version = YAML.load_file(data_location + 'version.yml')
        version['WindowsZones'] = TimezoneParser::Windows.getVersion
        if version['WindowsZones'].nil?
            $stderr.puts TimezoneParser::Windows.errors
        else
            timezones = TimezoneParser::Windows.getTimezones
            File.write(data_location + 'windows_offsets.yml', timezones.to_yaml)
            File.write(data_location + 'version.yml', version.to_yaml)
        end
    else
        puts 'Sorry, you must be running Windows'
    end
end

def import_timezones
    require 'timezone_parser/data/windows'
    os = Gem::Platform.local.os
    if (os == 'mingw32' or os == 'mingw64')
        metazones = YAML.load_file(vendor_location + 'tzres.yml')
        offsets = TimezoneParser::Windows.getMUIOffsets
        metazone_names = TimezoneParser::Windows.parseMetazones(metazones, offsets)
        File.write(data_location + 'windows_zonenames.yml', metazone_names.to_yaml)
    else
        puts 'Sorry, you must be running Windows'
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

desc 'Import Windows localized timezones from tzres.yml'
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
    # TODO: Implement YAML data export to binary format
end
