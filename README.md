# Aws::Site::Monitor

Monitor/map urls to AWS instance ids, and restart those instances in the event of a non 200 response.
(i.e. jankpress server on AWS which needs to be restarted intermittently for no apparent reason other than jankpress doing jankpress things)

Intended to be ran as a standalone executable, and has a mini DB to track urls/instance_ids

## Installation

``` ruby
gem install aws_site_monitor
```

## Usage

### Add a site to watch list
`bin/monitor add --url=https://www.google.com --instance-ids=12345 123456`

### Remove a site from watch list
`bin/monitor remove --url=https://www.google.com`

### Start watching
`bin/monitor start --check_every_seconds=30 --aws_region='us-east-1'`

Also make sure you have ENV variables set up for AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/aws-site-monitor.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
