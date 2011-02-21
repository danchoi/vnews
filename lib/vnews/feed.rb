# encoding: utf-8
require 'open-uri'
require 'feed_yamlizer'
require 'vnews/autodiscoverer'
require 'vnews/config'

class Vnews
  class Feed
    include Autodiscoverer

    USER_AGENT = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-us) AppleWebKit/534.16+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4"

    def self.get_feed(feed_url)
      response = open(feed_url, "User-Agent" => USER_AGENT)

      xml = response.read
      # puts response.last_modified
      $stderr.print "#{feed_url} -> Found #{response.content_type} #{response.charset}\n"

      charset = response.charset || "UTF-8"

      not_xml = response.content_type !~ /xml/ && xml[0,900] !~ /<?xml|<rss/
      if not_xml
        log "Can't find feed at #{feed_url}\nSnippet: #{xml[0,900]}\n\n=> Attempting autodiscovery"
        exit
        feed_url = auto_discover(feed_url)
        if feed_url 
          return get_feed(feed_url)
        else
          # log "No feed URL found at #{feed_url}"
          return nil
        end
      end
      feed_yaml = FeedYamlizer.run(xml, charset)
      feed_yaml
    rescue OpenURI::HTTPError, REXML::ParseException, NoMethodError, Timeout::Error
      $stderr.puts "  #{$!} : #{$!.message}"
    end

    def self.fetch_feed(xml_url, folder=nil)
      f = self.get_feed(xml_url)
      [xml_url, f, folder]
    end

    # f is the feed hash
    def self.save_feed(feed_url, f, folder=nil)
      # if no folder, we're just updating a feed
      if folder
        Vnews.sql_client.insert_feed(f[:meta][:title], feed_url, f[:meta][:link], folder)
      end
      f[:items].each do |item|
        if item[:guid].nil? || item[:guid].strip == ''
          item[:guid] = [f[:meta][:link], f[:link]].join(":::")
        end
        Vnews.sql_client.insert_item item.merge(:feed => feed_url, :feed_title => f[:meta][:title])
        $stderr.print "."
      end
    rescue
      puts "ERROR: dump: #{feed_url.inspect}, #{folder.inspect}: #{f.inspect} "
      raise
    end

    def self.update_feed(feed_title)
      require 'vnews/display'
      feed_title = Vnews::Display.strip_item_count(feed_title)
      puts "Updating feed: #{feed_title}"
      feed_url = Vnews.sql_client.feed_by_title feed_title
      puts "Fetching data from feed url: #{feed_url}"
      # puts "Deleting feed items for #{feed_url}"
      # Vnews.sql_client.delete_feed_items feed_url
      f = Vnews::Feed.get_feed feed_url
      save_feed feed_url, f, nil
      puts "\nFeed updated"
    end

    def self.log(text)
      $stderr.puts text
    end
  end
end

if __FILE__ == $0
  Vnews::Feed.new(ARGV.first, ARGV.last).fetch
end

