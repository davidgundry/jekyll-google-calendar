# Jekyll::Google::Calendar

A Jekyll plugin that generates pages for Google Calendar events fetched using the Google Calendar API. The event and calendar data is available through the `page` variable.

* `page.event` contains the data of the [event resource](https://developers.google.com/calendar/v3/reference/events#resource)
* `page.calendar` contains calendar information from the [API response](https://developers.google.com/calendar/v3/reference/events/list#response)
* `page.calendar_id` contains the calendar ID for the Google Calendar

You must have a Google API service account key and this service account must have read access to the calendars you with to read.

## Installation

Add this line to your Gemfile within the `jekyll_plugins` group.

```ruby
gem 'jekyll-google-calendar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jekyll-google-calendar

## Usage

Add `jekyll-google-calendar` to your _config.yml in the plugins array, eg:

```
plugins:
  - jekyll-feed
  - jekyll-google-calendar
```

Add the following configuration to your _config.yml, replacing the items in BLOCKCAPS with details for your own calendars.

```
gcalendar:
  key_file: PATH-TO-YOUR-GOOGLE-SERVICE-ACCOUNT-KEY.json
  calendars:
    - id: YOUR-CALENDAR-ID      # eg. blahblahblah12345678912345@group.calendar.google.com
      directory: events         # the directory in which to place geneated events
      layout: gc_event          # the Jekyll layout template to use for events
      date_format: "%d-%m-%Y"   # Uses Strftime formating directive (http://strftime.net/)
      look_ahead: 365           # 1 year in days
```

To use multiple calendars, add additional calendars to the calendars array following the pattern above.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidgundry/jekyll-google-calendar.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

### 0.1.1

Fixed critical bug for events with attendees.

### 0.1.0

Initial release