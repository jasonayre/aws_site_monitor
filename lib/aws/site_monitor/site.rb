module Aws
  module SiteMonitor
    class Site
      include ::Aws::SiteMonitor::PstoreRecord

      def initialize(**options)
        super(**options)
        @failure_count ||= 0
      end

      #this handles issues where instance cannot be restarted due to normal reboot.
      #since hard stopping takes longer, we don't want to do it unless necessary.
      #the reset failure count is semi wonky because it will reset even if success
      #hasnt yet been reached, however it is much less complicated than trying to
      #query state of multiple instances. basically if threshold is reached, hard stop
      #the instances, then on next pass since we reset the failure count, it should attempt
      #normal reboot, which will cause the instances to start
      def handle_failure!(options)
        hard_stop_enabled = options.attempts_until_hard_stop > 0

        if hard_stop_enabled && self[:failure_count] == options.attempts_until_hard_stop
          reset_failure_count
          stop_instances!
        else
          reboot_instances!
        end
      end

      def track_failure
        @failure_count = @failure_count + 1
        save
      end

      def reset_failure_count
        @failure_count = 0
        save
      end

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

      def stop_instances!
        ::Aws::SiteMonitor.ec2_client.stop_instances(
          instance_ids: self[:instance_ids]
        )
      rescue ::Aws::EC2::Errors::IncorrectState => e
        start_instances!
      end
    end
  end
end
