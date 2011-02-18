require 'nokogiri'
require 'vnews/feed'

class Vnews
  class Opml

    def self.import_feed(feed_node, folder=nil)
      xml_url = feed_node.attributes['xmlUrl'].to_s
      $stderr.puts "Importing #{xml_url}"
      Vnews::Feed.new(xml_url, folder).fetch
    end

    def self.import(opml)
      sqlclient = Vnews::SQLCLIENT

      doc = Nokogiri::XML.parse(opml) 
    
      doc.xpath('/opml/body/outline').each do |n|
        if n.attributes['xmlUrl']
          import_feed n
        else
          folder = n.attributes["title"].to_s
          $stderr.puts "folder: #{folder}"
          n.xpath("outline[@xmlUrl]").each do |m|
            import_feed m, folder
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  opml = STDIN.read
  Vnews::Opml.import(opml)
end
