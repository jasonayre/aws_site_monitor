module Aws
  module SiteMonitor
    class CLI < ::Thor
      option :check_every_seconds, :type => :numeric, :default => 60, :desc => 'Check every x seconds'
      option :aws_region, :type => :string, :default => 'us-east-1', :desc => 'AWS region'
      option :killswitch_url, :type => :string, :desc => 'If a file no longer exists at this url, kill script'
      option :request_timeout_seconds, :type => :numeric, :default => 15, :desc => 'How long to wait for response before request times out which will trigger a reboot'
      option :attempts_until_hard_stop, :type => :numeric, :default => 0, :desc => 'How many reboot attempts before attempting hard stop, 0 = disabled'

      desc "start", "Start Watching"
      def start
        configure!
        start_monitoring!
        sleep
      rescue => e
        puts "ERROR #{e.message}"
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


      desc "ls", "List sites being monitored"
      def ls
        sites = ::Aws::SiteMonitor::Site.all.map(&:attributes).join("\n")
        puts sites.inspect
      end

      desc "list_events", "List events"
      def list_events
        events = ::Aws::SiteMonitor::Event.all.map(&:attributes).join("\n")
        puts events.inspect
      end

      desc "clear_events", "Clear events"
      def clear_events
        ::Aws::SiteMonitor::Event.all.map(&:destroy)
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
            check_killswitch if check_killswitch?

            ::Aws::SiteMonitor::Site.all.each do |site|
              puts "MAKING REQUEST TO #{site[:url]}"
              result = `curl -s -o /dev/null -I -w "%{http_code}" --max-time #{options.request_timeout_seconds} #{site[:url]}`

              if result[0] == "2"
                puts "GOT 200 EVERYTHING OK"
                site.reset_failure_count
              else
                site.track_failure
                ::Aws::SiteMonitor::Event.create(:status_code => result)
                site.handle_failure!(options)
              end
            end
          end
        end

        def check_killswitch
          puts "CHECKING KILLSWITCH #{options.killswitch_url}"
          result = `curl -s -o /dev/null -I -w "%{http_code}" -L #{options.killswitch_url}`
          puts result
          kill_process! if result[0] != "2"
        end

        def check_killswitch?
          !!options.killswitch_url
        end

        #because we are in a new thread with the timer task, exit/abort wont work
        def kill_process!
          ::Process.kill 9, ::Process.pid
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
