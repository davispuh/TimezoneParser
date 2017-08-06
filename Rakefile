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
    require 'active_support/version'
    require 'active_support/time'
    TimezoneParser::TZInfo::init
    countries = TimezoneParser::TZInfo::getTimezoneCountries
    abbreviations = TimezoneParser::TZInfo::getAbbreviations
    timezones = TimezoneParser::CLDR::getTimezones
    metazones = TimezoneParser::CLDR::getMetazones
    windowsZones = TimezoneParser::CLDR::getWindowsZones
    TimezoneParser::CLDR::updateAbbreviations(abbreviations)
    version = YAML.load_file(data_location + 'version.yml')
    version['TZInfo'] = TimezoneParser::TZInfo::getVersion
    version['CLDR'] = TimezoneParser::CLDR::getVersion
    version['Rails'] = ActiveSupport::VERSION::STRING
    version['WindowsZones'] = nil unless version.has_key?('WindowsZones')
    options = { :cr_newline => false, :encoding => 'UTF-8:UTF-8' }
    File.write(data_location + 'countries.yml', countries.to_yaml, options)
    File.write(data_location + 'timezones.yml', timezones.to_yaml, options)
    File.write(data_location + 'metazones.yml', metazones.to_yaml, options)
    File.write(data_location + 'windows_timezones.yml', windowsZones.to_yaml, options)
    abbreviations = Hash[abbreviations.to_a.sort_by { |d| d.first } ]
    File.write(data_location + 'abbreviations.yml', abbreviations.to_yaml, options)
    rails = Hash[ActiveSupport::TimeZone::MAPPING.to_a.sort_by { |d| d.first } ]
    File.write(data_location + 'rails.yml', rails.to_yaml, options)
    File.write(data_location + 'version.yml', version.to_yaml, options)
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
    File.write(data_location + 'rails_i18n.yml', names.to_yaml, { :cr_newline => false, :encoding => 'UTF-8:UTF-8' })
end

def update_windows
    os = Gem::Platform.local.os
    if (os == 'mingw32' or os == 'mingw64')
        require 'timezone_parser/data/windows'
        options = { :cr_newline => false, :encoding => 'UTF-8:UTF-8' }
        version = YAML.load_file(data_location + 'version.yml')
        version['WindowsZones'] = TimezoneParser::Windows.getVersion
        if version['WindowsZones'].nil?
            $stderr.puts TimezoneParser::Windows.errors
        else
            timezones = TimezoneParser::Windows.getTimezones
            File.write(data_location + 'windows_offsets.yml', timezones.to_yaml, options)
            File.write(data_location + 'version.yml', version.to_yaml, options)
        end
    else
        puts 'Skipped Windows Zone update. Need to be run from Windows.'
    end
end

def import_timezones
    require 'timezone_parser/data/windows'
    os = Gem::Platform.local.os
    if (os == 'mingw32' or os == 'mingw64')
        unless File.exist?(vendor_location + 'tzres.yml')
          puts 'File `tzres.yml` not found. Windows Zone name importing skipped.'
          return
        end
        metazones = YAML.load_file(vendor_location + 'tzres.yml')
        offsets = TimezoneParser::Windows.getMUIOffsets
        metazone_names = TimezoneParser::Windows.parseMetazones(metazones, offsets)
        File.write(data_location + 'windows_zonenames.yml', metazone_names.to_yaml, { :cr_newline => false, :encoding => 'UTF-8:UTF-8' })
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
    ['abbreviations.yml', 'timezones.yml', 'countries.yml', 'metazones.yml',
        'windows_zonenames.yml', 'windows_timezones.yml', 'windows_offsets.yml',
        'rails.yml', 'rails_i18n.yml'].each do |name|
        path = data_location + name
        Marshal.dump(YAML.load_file(path), File.open(path.dirname + (path.basename('.*').to_s + '.dat'), 'wb'))
    end
end
