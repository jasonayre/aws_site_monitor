module Aws
  module SiteMonitor
    class Event
      include ::Aws::SiteMonitor::PstoreRecord

      def initialize(occured_at: ::Time.now, status_code:, **attributes)
        super(occured_at: occured_at, status_code: status_code, **attributes)
      end
    end
  end
end
