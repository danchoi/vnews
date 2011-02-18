# encoding: utf-8
require 'open-uri'
require 'feed_yamlizer'
require 'vnews/autodiscoverer'
require 'vnews/sql'

class Vnews
  class Feed
    include Autodiscoverer

    USER_AGENT = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-us) AppleWebKit/534.16+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4"

    def initialize(url, folder)
      @url = url
      @folder = folder
      @sqlclient = Vnews::SQLCLIENT
    end

    def get_feed(feed_url)
      response = open(feed_url, "User-Agent" => USER_AGENT)

      xml = response.read
      # puts response.last_modified
      $stderr.puts "  -> Found #{response.content_type} #{response.charset}"

      charset = response.charset || "ISO-8859-1"

      not_xml = response.content_type !~ /xml/ && xml[0,900] !~ /<?xml|<rss/
      if not_xml
        log "Can't find feed at #{feed_url}\nSnippet: #{xml[0,900]}\n\n=> Attempting autodiscovery"
        exit
        feed_url = auto_discover(feed_url)
        if feed_url 
          return get_feed(feed_url)
        else
          log "No feed URL found at #{feed_url}"
          nil
        end
      end
      feed_yaml = FeedYamlizer.run(xml, charset)
    rescue OpenURI::HTTPError, REXML::ParseException
      $stderr.puts "  #{$!} : #{$!.message}"
    end

    def fetch
      f = get_feed @url
      return unless f
      @sqlclient.insert_feed(f[:meta][:title], f[:meta][:link], @folder)
      f[:items].each do |item|
        if item[:guid].nil? || item[:guid].strip == ''
          item[:guid] = [f[:meta][:link], Time.now.to_i].join("@@@")
        end
        @sqlclient.insert_item item.merge(:feed => f[:meta][:link], :feed_title => f[:meta][:title])
      end
    end

    def log(text)
      $stderr.puts text
    end
  end
end

if __FILE__ == $0
  Vnews::Feed.new(ARGV.first, ARGV.last).fetch
end

