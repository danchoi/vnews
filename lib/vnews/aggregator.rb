require 'rexml/document'
require 'nokogiri'
require 'open-uri'
require 'feed_yamlizer'
require 'vnews/autodiscoverer'

class Vnews
  class Aggregator
    include Autodiscoverer
    def initialize(config={})
    end

    def get_feed(feed_url)
      feed_url = repair feed_url
      response = open(feed_url)
      xml = response.read
      # puts response.last_modified
      puts response.content_type
      puts response.charset
      charset = response.charset || "ISO-8859-1"

      if response.content_type !~ /xml/
        log "Can't find feed at #{feed_url}\nAttempting autodiscovery"
        feed_url = auto_discover(feed_url)
        if feed_url 
          return get_feed(feed_url)
        else
          nil
        end
      end
      puts "Running"
      feed_yaml = FeedYamlizer.run(xml, charset)
    end

    # input is a hash
    def print_feed(url)
      f = get_feed url
      f[:items].each {|i|
        puts '-' * 80
        puts i[:title]
        puts
        header = []
        header << i[:link]
        header << i[:pub_date].strftime("%b %d")
        if i[:author]
          header << "By #{i[:author]}"
        end
        puts header.map {|x| "    " + x.to_s}.join("\n\n")
        puts
        puts i[:content][:text].strip.gsub(/^/, "    ") # indent body 4 spaces
        puts
      }
    end

    def import_opml(opml)
      doc = REXML::Document.new(opml) 
      feed_urls = doc.elements.map('//outline[@xmlUrl]') do |e|
        e.attributes['xmlUrl']
      end.uniq.each do |url|
        # TODO
    
      end
    end
   
    def repair(feed_url)
      unless feed_url =~ /^http:\/\//
        feed_url = "http://" + feed_url
      end
      feed_url.strip
    end

    def log(text)
      $stderr.puts text
    end



  end
end

if __FILE__ == $0
  Vnews::Aggregator.new.print_feed(ARGV.first)
end
