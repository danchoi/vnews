require 'nokogiri'

class Vnews
  class AutodiscoveryFailed < StandardError;  end

  module Autodiscoverer
    def auto_discover(feed_url)
      html = open(feed_url)
      doc = Nokogiri::HTML.parse(html)
      feed_url = [ 'head link[@type=application/atom+xml]', 
        'head link[@type=application/rss+xml]', 
        "head link[@type=text/xml]"].detect do |path|
          doc.at(path)
        end
      if feed_url
        feed_url
      else
        nil
      end
    rescue Errno::ECONNRESET, Nokogiri::CSS::SyntaxError
      $stderr.puts $!
    end
  end
end
