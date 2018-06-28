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

        ::Aws::EC2::Client.new(region: AWS_REGION)
      end
    end

    def self.register(url:, instance_ids:)
      ::Aws::SiteMonitor::Site.create(url: url, instance_ids: instance_ids)
    end

    def self.unregister(url:)
      ::Aws::SiteMonitor::Site.find_by(:url => url)
    end

    class Event
      include ::Aws::SiteMonitor::PstoreRecord

      def initialize(occured_at: ::Time.now, status_code:, **attributes)
        super(occured_at: occured_at, status_code: status_code, **attributes)
      end
    end

    class Site
      include ::Aws::SiteMonitor::PstoreRecord
    end

    class RestartTask
      def initialize(site)
        @site = site
      end

      def run
        ::Aws::SiteMonitor.ec2_client.reboot_instances({
          instance_ids: @site[:instance_ids]
        })
      end

      # todo: maybe support hard shutdown / start
      # def stop
      #   begin
      #     Aws::SiteMonitor.ec2_client.stop_instances
      #     ec2.wait_until(:instance_stopped, instance_ids:[@id])
      #     puts "instance stopped"
      #   rescue Aws::Waiters::Errors::WaiterFailed => error
      #     puts "failed waiting for instance running: #{error.message}"
      #   end
      # end
    end
  end
end
