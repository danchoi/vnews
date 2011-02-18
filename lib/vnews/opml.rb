require 'nokogiri'
require 'vnews/feed'

class Vnews
  class Opml

    def self.import_opml(opml)
      doc = REXML::Document.new(opml) 
        # TODO find category
      feed_urls = doc.elements.map('//outline[@xmlUrl]') do |e|
        e.attributes['xmlUrl']
      end.uniq.each do |url|
    
      end
    end
   
  end
end
