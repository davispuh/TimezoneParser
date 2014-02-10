source 'https://rubygems.org'

group :development, :test do
    gem 'redcarpet',  :platforms => [:ruby, :mswin, :mingw]
    gem 'kramdown',   :platforms => :jruby
    gem 'coveralls',  require: false if ENV['CI']
end

# Specify your gem's dependencies in TimezoneParser.gemspec
gemspec
