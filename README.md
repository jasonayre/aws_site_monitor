# Aws::Site::Monitor

Monitor/map urls to AWS instance ids, and restart those instances in the event of a non 200 response.
(i.e. jankpress server on AWS which needs to be restarted intermittently for no apparent reason other than jankpress doing jankpress things)

Intended to be ran as a standalone executable, and has a mini DB to track urls/instance_ids



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws-site-monitor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws_site_monitor

## Usage

** Add a site to watch list **

bin/watchlist add --url=https://www.google.com --instance-ids=12345 123456
bin/watchlist remove --url=https://www.google.com



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/aws-site-monitor.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
