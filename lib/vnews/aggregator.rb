require 'rexml/document'
require 'nokogiri'
require 'open-uri'
require 'feedzirra'
require 'logger'
require 'yaml'
require 'vnews/couch'

class Vnews
  class Aggregator
    def initialize(config={})
      @logger = Logger.new(config[:logfile] || STDERR)
    end

    def list_feeds(keys={})
      Couch.show_view("feeds_with_entries", keys)
    end

    def subscribe(url)
      feed = get_feed(url)
      # store in couchdb
      entries = feed.delete(:entries)
      feeddoc = Couch.create_or_update(feed)
      entries.each do |entry|
        Couch.create_or_update(entry)
      end
      feeddoc
    end

    def get_feed(feed_url)
      feed_url = repair feed_url
      feed = Feedzirra::Feed.fetch_and_parse feed_url
      if feed.nil?
        log "Can't find feed at #{feed_url}\nAttempting autodiscovery"
        feed_url = auto_discover(feed_url)
        if feed_url
          puts "Subscribing to #{feed_url}"
          feed = Feedzirra::Feed.fetch_and_parse feed_url
        else
          raise SubscribeFailed
        end
      end
      feed_to_hash(feed_url, feed)
    end

    def feed_to_hash(feed_url, feed)
      #feed.sanitze_entries!  # doesn't work on recent versions of Feedzirra for some reason
      { 
        :title => feed.title,
        # It's very importannt that this is feed_url and not feed.url:
        :link => feed.url, 
        :feed_url => feed_url,
        '_id' => feed_url,
        'type' => "feed",
        :etag => feed.etag, 
        :last_modified => feed.last_modified,
        :entries => feed.entries.map {|entry|
          {:title => entry.title.sanitize,
            '_id' => entry.url,
            'type' => "feed_entry",
            'feed_id' => feed_url,
            :url => entry.url,
            :author => entry.author,
            :summary => entry.summary,
            :content => entry.content,
            :published => entry.published,
            :categories => entry.categories }}
      }
    end

    def auto_discover(feed_url)
      doc = Nokogiri::HTML.parse(fetch(feed_url))
      feed_url = [ 'head link[@type=application/atom+xml]', 
        'head link[@type=application/rss+xml]', 
        "head link[@type=text/xml]"].detect do |path|
          doc.at(path)
        end
      if feed_url
        feed_url
      else
        raise AutodiscoveryFailed, "can't discover feed url at #{url}"
      end
    end

    def import_opml(opml)
      doc = REXML::Document.new(opml) 
      feed_urls = doc.elements.map('//outline[@xmlUrl]') do |e|
        e.attributes['xmlUrl']
      end.uniq.each do |url|
        # TODO
        subscribe(url)
      end
    end
   
    def repair(feed_url)
      unless feed_url =~ /^http:\/\//
        feed_url = "http://" + feed_url
      end
      feed_url.strip
    end

    def log(text)
      @logger.debug text
    end

    def self.start_drb_server(config)
      outline = self.new(config)
      use_uri = config['drb_uri'] || nil # redundant but explicit
      DRb.start_service(use_uri, outline)
      DRb.uri
    end
  end
end

if __FILE__ == $0
  vnews = Vnews::Aggregator.new
  res = vnews.subscribe ARGV.first
end

