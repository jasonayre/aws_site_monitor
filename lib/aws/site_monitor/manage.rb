module Aws
  module SiteMonitor
    class Manage < ::Thor
      option :url, :type => :string, :desc => 'URL to watch'
      option :instance_ids, :type => :array, :desc => 'AWS Instance IDS to restart when non 200 response is detected'

      desc "add", "Add a site to the watch list"
      def add
        site = ::Aws::SiteMonitor::Site.create(:url => options.url, :instance_ids => options.instance_ids)
        puts "added #{options[:url]} to watchlist"
      end

      option :url, :type => :string, :desc => 'URL to remove from watchlist'
      desc "remove", "Remove a site from the watch list"
      def remove
        site = ::Aws::SiteMonitor::Site.find_by(:url => options.url)
        raise ::StandardError.new("SiteNotFound #{options.url}") if !site
        site.destroy
        puts "removed #{site[:url]} from watchlist"
      end
    end
  end
end
