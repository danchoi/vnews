require 'rexml/document'
require 'nokogiri'
require 'open-uri'
require 'feed_yamlizer'
require 'vnews/autodiscoverer'

class Vnews
  class Aggregator
    include Autodiscoverer

    def initialize(out=nil)
      @out = out
    end

    def get_feed(feed_url)
      feed_url = repair feed_url
      response = open(feed_url)
      xml = response.read
      # puts response.last_modified
      $stderr.puts response.content_type
      $stderr.puts response.charset
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
      $stderr.puts "Running"
      feed_yaml = FeedYamlizer.run(xml, charset)
    end

    def munge_title(title)
      title.gsub(/\W/, '-') + '.txt'
    end

    # f is a hash; get from get_feed()
    def feed_to_s(f)
      out = []
      f[:meta].each {|k, v| out << "# #{v}" }
      out << ''
      f[:items].each do |i|
        out << '-' * 10
        out << ''
        out << i[:title]
        out << ''
        header = []
        header << i[:pub_date].strftime("%b %d")
        if i[:author]
          header << "By #{i[:author]}"
        end
        out << header.map {|x| "    " + x.to_s}.join("\n\n")
        out << ''
        out << i[:content][:text].strip.gsub(/^/, "    ") # indent body 4 spaces
        out << ''
        out << "    #{i[:link]}"
        out << ''
      end
      out.join("\n")
    end

    # input is a hash
    def print_feed(url)
      f = get_feed url
      file = @out || munge_title(f[:meta][:title])
      File.open(file, 'w') do |out|
        out.puts feed_to_s(f)
      end
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
      stderr.puts text
    end
  end
end

if __FILE__ == $0
  Vnews::Aggregator.new.print_feed(ARGV.first)
end
