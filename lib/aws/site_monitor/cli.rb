module Aws
  module SiteMonitor
    class CLI < ::Thor
      option :check_every_seconds, :type => :numeric, :default => 5, :desc => 'Check every x seconds'
      option :aws_region, :type => :string, :default => 'us-east-1', :desc => 'AWS region'

      desc "start", "Start Watching"
      def start
        configure!
        start_monitoring!
        sleep
      rescue => e
        puts e.inspect
        start_monitoring!
      end

      option :url, :type => :string, :desc => 'URL to watch', :required => true
      option :instance_ids, :type => :array, :desc => 'AWS Instance IDS to restart when non 200 response is detected', :required => true

      desc "add", "Add a site to the watch list"
      def add
        site = ::Aws::SiteMonitor::Site.create(:url => options.url, :instance_ids => options.instance_ids)
        puts "added #{options[:url]} to watchlist"
      end

      option :url, :type => :string, :desc => 'URL to remove from watchlist', :required => true
      desc "remove", "Remove a site from the watch list"
      def remove
        site = ::Aws::SiteMonitor::Site.find_by(:url => options.url)
        raise ::StandardError.new("SiteNotFound #{options.url}") if !site
        site.destroy
        puts "removed #{site[:url]} from watchlist"
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
