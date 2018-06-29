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
`aws_site_monitor add --url=https://www.google.com --instance-ids=12345 123456`

### Remove a site from watch list
`aws_site_monitor remove --url=https://www.google.com`

### List sites on watchlist
`aws_site_monitor ls`

### Start watching
`aws_site_monitor start --check_every_seconds=60 --request_timeout_seconds=15 --aws_region='us-east-1'`

### Watch sites with killswitch url
Basically this feature is if you are running the script on a local server, i.e. raspberry pi,
and you want to stop the process without physical access to it. You can pass in a killswitch_url,
which can be for instance a dropbox url. Then if you need to kill the script,
you can just delete the file.

`aws_site_monitor start --killswitch_url=https://www.dropbox.com/s/gtcocntwdm6ae16/site_monitor_killswitch.txt?dl=0`

### List events (only tracked when non 200 response occurs)
`aws_site_monitor list_events`

### Clear events
`aws_site_monitor clear_events`


Also make sure you have ENV variables set up for AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/aws-site-monitor.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
