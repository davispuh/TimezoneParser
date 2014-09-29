# TimezoneParser

## Probably the best, most complete Timezone parsing library ever made!

Library for parsing Timezone names and abbreviations to corresponding UTC offsets and much more. Supports multiple languages.

## Features

* Parse Timezone name to UTC offset
* Support for all TZ database abbreviations
* Ruby on Rails Timezone names supported
* Recognition of localized timezone names
* Check if string is a valid Timezone or abbreviation
* Present and Historical Timezones and offsets
* Filter results by Time, Region, Locale and DST


Input formats:

* Timezone abbreviations (eg. "EST")
* Timezone names (eg. "China Summer Time")
* Localized Timezone names in different languages (eg. "阿尤恩")
* Windows zone names (eg. "Azerbaijan Summer Time")
* Localized Windows zone names (eg. "كوريا - التوقيت الرسمي")
* Ruby on Rails Timezone names (eg. "Eastern Time (US & Canada)")
* Translated Ruby on Rails Timezone names (eg. "노보시비르스크")


Output formats:

* UTC offsets (eg. "-18000")
* Timezone identifiers (eg. "Europe/Istanbul")
* Original Zone (eg. "Mid-Atlantic Standard Time")
* Metazones (eg. "North_Mariana")


## Installation

Add this line to your application's Gemfile:

    gem 'TimezoneParser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install TimezoneParser


### Dependencies

* tzinfo (only required for Timezone offsets in some cases)
* insensitive_hash

## Usage Example

### To get UTC offsets from Timezone abbreviations

```ruby
> require 'timezone_parser'
=> true
> offsets = TimezoneParser::Abbreviation.new('FKT').getOffsets
=> [-14400]
> offsets.first
=> -14400
```

### Timezone name to Timezone identifier

```ruby
> TimezoneParser::Timezone.new('Nord-Marianene-tid').getTimezones
=> ["Pacific/Saipan"]
```

### Localized Windows zone to original Windows zone identifier

```ruby
> TimezoneParser::WindowsZone.new('Jerusalem (normaltid)').getZone
=> "Israel Standard Time"
```

### Find actual Timezones from uknown platform-dependent Ruby zone

```ruby
> tz = Time.now.zone # on localized Windows
=> "FLE standarta laiks"
> TimezoneParser::getTimezones(tz)
=> ["Europe/Helsinki", "Europe/Kiev", "Europe/Mariehamn", "Europe/Riga", "Europe/Simferopol", "Europe/Sofia", "Europe/Tallinn", "Europe/Uzhgorod", "Europe/Vilnius", "Europe/Zaporozhye"]
```

## Documentation

YARD with markdown is used for documentation (`redcarpet` required)

## Specs

RSpec and simplecov are required, to run tests just `rake spec`
code coverage will also be generated

## Code status
[![Gem Version](https://badge.fury.io/rb/TimezoneParser.png)](http://badge.fury.io/rb/TimezoneParser)
[![Build Status](https://travis-ci.org/davispuh/TimezoneParser.png?branch=master)](https://travis-ci.org/davispuh/TimezoneParser)
[![Dependency Status](https://gemnasium.com/davispuh/TimezoneParser.png)](https://gemnasium.com/davispuh/TimezoneParser)
[![Coverage Status](https://coveralls.io/repos/davispuh/TimezoneParser/badge.png?branch=master)](https://coveralls.io/r/davispuh/TimezoneParser?branch=master)
[![Code Climate](https://codeclimate.com/github/davispuh/TimezoneParser.png)](https://codeclimate.com/github/davispuh/TimezoneParser)

## Other

Did you found this library useful? Tell about it [![Tweet #2FTimezoneParser](http://i.imgur.com/ah3eSk3.png)](https://twitter.com/intent/tweet?hashtags=TimezoneParser&original_referer=https%3A%2F%2Fgithub.com%2Fdavispuh%2FTimezoneParser&related=davispuh&tw_p=tweetbutton&url=https%3A%2F%2Fgithub.com%2Fdavispuh%2FTimezoneParser)

You can also [![Flattr FTimezoneParser](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=davispuh&url=https%3A%2F%2Fgithub.com%2Fdavispuh%2FTimezoneParser&title=TimezoneParser&language=english&tags=github&category=software) 

## Unlicense

![Copyright-Free](http://unlicense.org/pd-icon.png)

All text, documentation, code and files in this repository are in public domain (including this text, README).
It means you can copy, modify, distribute and include in your own work/code, even for commercial purposes, all without asking permission.

[About Unlicense](http://unlicense.org/)

## Contributing

Feel free to improve as you see.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Export `.yml` data files to binary `.dat` with `rake export`
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request


**Warning**: By sending pull request to this repository you dedicate any and all copyright interest in pull request (code files and all other) to the public domain. (files will be in public domain even if pull request doesn't get merged)

Also before sending pull request you acknowledge that you own all copyrights or have authorization to dedicate them to public domain.

If you don't want to dedicate code to public domain or if you're not allowed to (eg. you don't own required copyrights) then DON'T send pull request.
