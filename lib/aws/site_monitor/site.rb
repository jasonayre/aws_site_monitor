module Aws
  module SiteMonitor
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
