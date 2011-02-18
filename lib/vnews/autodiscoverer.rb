require 'nokogiri'

class Vnews
  class AutodiscoveryFailed < StandardError;  end

  module Autodiscoverer
    def auto_discover(feed_url)
      doc = Nokogiri::HTML.parse(open(feed_url))
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
  end
end
