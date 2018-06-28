require "aws/site_monitor/version"
require "thor"
require "concurrent"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require 'aws-sdk'
require 'pstore'
require 'aws/site_monitor/pstore_record'

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

      def restart
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

    class Monitor < ::Thor
      option :check_every_seconds, :type => :numeric, :default => 5, :desc => 'Check every x seconds'
      option :aws_region, :type => :string, :default => 'us-east-1', :desc => 'AWS region'

      desc "start", "Start Watching"
      def start
        configure!
        start_monitoring!
      rescue => e
        puts e.inspect
        start_monitoring!
      end

      no_tasks do
        def configure!
          configure_traps
        end

        # Configure signal traps.
        def configure_traps
          exit_signals = [:INT, :TERM]
          exit_signals << :QUIT unless defined?(JRUBY_VERSION)

          exit_signals.each do |signal|
            trap(signal) do
              puts "Stopping"
              exit(0)
            end
          end
        end

        def monitor_task
          @monitor_task ||= ::Concurrent::TimerTask.new(
            execution_interval: options.check_every_seconds,
            timeout_interval: options.check_every_seconds
          ) do
            puts "HITTING MAIN BLOCK"
            tasks = ::Aws::SiteMonitor::Site.all.map do |site|
              puts "MAKING REQUEST TO #{site[:url]}"
              result = `curl -s -o /dev/null -I -w "%{http_code}" #{site[:url]}`
              puts result.inspect

              if result[0] === "2"
                puts "GOT 200 EVERYTHING OK"
                nil
              else
                ::Aws::SiteMonitor::Event.create(:status_code => result)
                ::Aws::SiteMonitor::RestartTask.new(site)
              end
            end
          end
        end

        def start_monitoring!
          monitor_task.shutdown if @monitor_task
          @monitor_task = nil
          monitor_task.execute
        end
      end
    end
  end
end
