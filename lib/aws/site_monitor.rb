require "aws/site_monitor/version"
require "thor"
require "concurrent"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require 'aws-sdk'
require 'pstore'
require 'aws/site_monitor/pstore_record'
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

    class Event
      include ::Aws::SiteMonitor::PstoreRecord

      def initialize(occured_at: ::Time.now, status_code:, **attributes)
        super(occured_at: occured_at, status_code: status_code, **attributes)
      end
    end

    class Site
      include ::Aws::SiteMonitor::PstoreRecord

      def reboot_instances!
        puts "RESTARTING SITE #{self.attributes}"
        ::Aws::SiteMonitor.ec2_client.reboot_instances(
          instance_ids: self[:instance_ids]
        )
      rescue ::Aws::EC2::Errors::IncorrectState => e
        puts e.message
        start_instances!
      end

      def start_instances!
        puts "STARTING STOPPED INSTANCES"
        ::Aws::SiteMonitor.ec2_client.start_instances(
          instance_ids: self[:instance_ids]
        )
      end
    end
  end
end
