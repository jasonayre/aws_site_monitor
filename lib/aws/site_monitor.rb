require "aws/site_monitor/version"
require "thor"
require "concurrent"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require 'aws-sdk'
require 'pstore'
require 'aws/site_monitor/pstore_record'
require 'aws/site_monitor/site'
require 'aws/site_monitor/event'
require 'aws/site_monitor/cli'

ENV['AWS_REGION'] ||= 'us-east-1'

module Aws
  module SiteMonitor
    def self.ec2_client
      @ec2_client ||= begin
        ::Aws.config.update({
          credentials: ::Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
        })

        ::Aws::EC2::Client.new(region: ENV['AWS_REGION'])
      end
    end
  end
end
